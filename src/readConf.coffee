stat = null
readdir = null
path = null
merge = null
hash = null
start = =>
  unless stat?
    {stat,readdir} = require "fs-extra"
    path = require "path"
    {createHash} = require "crypto"
    hash = (obj) => createHash("md5").update(JSON.stringify(obj)).digest("hex")
    requireFromCWD = (name) =>
      entry = require.resolve(name, { paths: [path.join(process.cwd(), "node_modules")] })
      require entry
    try
      requireFromCWD "coffeescript/register"
    catch
      try
        requireFromCWD "coffee-script/register"
    try
      requireFromCWD "ts-node/register"
    try
      requireFromCWD "babel-register"
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
  conf.hash = hash(conf)
  conf.mtime = stats.mtimeMs
  conf = merge o.default, conf if o.default?
  conf = merge conf, o.assign if o.assign?
  return conf


chokidar = null
uncache = null
watch = (o) =>
  chokidar ?= require "chokidar"
  uncache ?= require("recursive-uncache")

  unwatchedModules = []
  filesToWatch = []
  isDone = true
  isCanceling = false
  hasChanged = false
  oldHash = 0
  done = (promise) =>
    wasDone = isDone
    isDone = false
    conf = await promise
    if conf.hash != oldHash
      oldHash = conf.hash
      unless wasDone
        hasChanged = false
        isCanceling = true
        try
          await o.cancel?()
        catch e
          console.log e
        isCanceling = false
        conf = await readConf(o) if hasChanged
      try
        await o.cb(conf)
      catch e
        console.log e
    isDone = true

  for k,v of require.cache
    unwatchedModules.push k

  promise = readConf(o)
  conf = await promise

  for k,v of require.cache
    filesToWatch.push k unless ~unwatchedModules.indexOf(k)
  watcher = chokidar.watch filesToWatch, ignoreInitial: true
  watcher.on "all", (e, filepath) =>
    uncache(filepath,__filename)
    hasChanged = true
    unless isCanceling
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