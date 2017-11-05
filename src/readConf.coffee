stat = null
readdir = null
path = null
merge = null
start = =>
  unless stat?
    {stat,readdir} = require "fs-extra"
    path = require "path"
    try
      require "coffeescript/register"
    catch
      try
        require "coffee-script/register"
    try
      require "ts-node/register"
    try
      require "babel-register"
    merge = require "merge-options"

readConf = (o) =>
  start()
  unless (confPath = o?.filename)?
    if typeof o == "string" or o instanceof String
      name = o
    else 
      if not o.name?
        throw new Error "read-conf: no name or filename for config was given"
      else
        name = o.name
    folders = o.folders || [process.cwd()]
    folders = [folders] unless Array.isArray(folders)
    exts = o.extensions || ["js","coffee","ts","json"]
    for folder in folders
      folder = path.resolve(folder)
      files = await readdir(folder)
      for ext in exts
        if ~files.indexOf(tmp = "#{name}.#{ext}")
          conf = tmp
          break
      break if conf
    throw new Error "read-conf: no file '#{name}' found" unless conf 
    confPath = o.filename = path.resolve(folder, conf)
  try
    conf = require confPath
  catch e
    throw new Error "read-conf: couldn't require '#{confPath}'"
  stats = await stat confPath
  conf.mtime = stats.mtimeMs
  conf = merge o.default, conf if o.default?
  return conf


chokidar = null
uncache = null
watch = (o) =>
  chokidar ?= require "chokidar"
  uncache ?= require("recursive-uncache")

  unwatchedModules = []
  filesToWatch = []
  isDone = false
  isCanceling = false
  done = (promise) =>
    promise.then(o.cb)
    .then => isDone = true
    .catch (e) => console.log e

  for k,v of require.cache
    unwatchedModules.push k

  promise = readConf(o)
  conf = await promise

  for k,v of require.cache
    filesToWatch.push k unless ~unwatchedModules.indexOf(k)
  watcher = chokidar.watch filesToWatch, ignoreInitial: true
  watcher.on "all", (e, filepath) =>
    uncache(filepath,__filename)
    unless isCanceling
      unless isDone
        isCanceling = true
        await o.cancel?() 
        isCanceling = false
      else
        isDone = false
      done(readConf(o))

  setTimeout (=>done(promise)),0

  return => 
    watcher.close()
    for filepath in filesToWatch
      uncache(filepath,__filename)

module.exports = (o) =>
  if o.watch
    return watch(o)
  else
    result = readConf(o)
    if o.cb
      result.then(o.cb) 
      return =>
    return result