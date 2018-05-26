stat = null
readdir = null
pathExists = null
path = null
mergeOptions = null
hash = null
resolveFrom = null
chokidar = null
uncache = null
chalk = null
validate = require "./validate"
start = (o) =>
  unless stat?
    {stat,readdir,pathExists} = require "fs-extra"
    path = require "path"
    {createHash} = require "crypto"
    hash = (obj) => createHash("sha1").update(JSON.stringify(obj, (key,val) =>
      if typeof val == "function"
        val.toString()
      else
        val
    )).digest("base64")
    importCwd = require "import-cwd"
    importCwd.silent "coffee-script/register"
    importCwd.silent "coffeescript/register"
    importCwd.silent "ts-node/register"
    importCwd.silent "babel-register"
    resolveFrom = require "resolve-from"
    mergeOptions = require "merge-options"
    chalk = require "chalk"
    
  if o.watch and not chokidar?
    chokidar = require "chokidar"
    uncache = require "recursive-uncache"
    
isString = (o) => typeof o == "string" or o instanceof String
readConfig = (o) =>
  start(o)
  unless (confPath = o?.filename)?
    if isString(o)
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
      if await pathExists folder
        files = await readdir(folder)
        for ext in exts
          if ~files.indexOf(tmp = "#{name}.#{ext}")
            conf = tmp
            break
        break if conf
    confPath = o.filename = path.resolve(folder, conf) if conf

  if confPath
    statsDone = stat(confPath).then (stats) => o.mtime = stats.mtimeMs
    .catch =>
      unless o.required == false
        throw new Error "read-conf: no file '#{name}' found"

  if o.watch
    unwatchedModules = []
    for k,v of require.cache
      unwatchedModules.push k
    
  try
    conf = require confPath
  catch e
    unless o.required == false
      throw new Error "read-conf: couldn't require '#{confPath}'"
    else
      conf = {}

  o.hash = hash(conf)

  merge = mergeOptions.bind(concatArrays: o.concatArrays)
  conf = merge o.default, conf if o.default?
  conf = merge conf, o.assign if o.assign?

  base = o.base || {}
  base[o.prop or "config"] = conf
  base.readConfig = o

  if (schema = o.schema)?
    if isString(schema)
      schema = require schema
    addToSchema = validate.getAdder(schema)
    ignoreDefaults = []
    isValid = true
    validate2 = (obj) =>
      validate obj, schema, isNormalized:true, ignore: ignoreDefaults
      .catch (problems) =>
        if problems instanceof Error
          throw problems
        else
          console.error chalk.red.bold "\n\nInvalid configuration\n"
          console.error chalk.red("File: ")+chalk.underline("#{confPath}\n")
          console.error chalk.red("Problems:")
          console.error chalk.dim " - " + problems.join("\n - ") + "\n\n"
        isValid = false

  
  if (plgs = o.plugins)?
    pluginProp = plgs.prop or "plugins"
    disableProp = plgs.disableProp or "disablePlugins"
    if schema
      if (def = schema[pluginProp]?.default)?
        tmp = {}
        tmp2 = tmp[pluginProp] = conf[pluginProp] ?= []
        for str in def
          tmp2.push str unless ~tmp2.indexOf(str)
        await validate2 tmp
        ignoreDefaults.push pluginProp
      if (def = schema[disableProp]?.default)?
        tmp = {}
        tmp2 = tmp[disableProp] = conf[disableProp] ?= []
        for str in def
          tmp2.push str unless ~tmp2.indexOf(str)
        await validate2 tmp
        ignoreDefaults.push disableProp
    if (prep = plgs.prepare)?
      prep(conf)
    pluginPaths = plgs.paths or [process.cwd()]
    resolvers = pluginPaths.map (folder) =>
      resolveFrom.silent.bind null, folder
    tmp = plgs.plugins or conf[pluginProp]
    if (disablePlugins = plgs.disablePlugins or conf[disableProp])? and disablePlugins.length > 0
      tmp = tmp.filter (name) => not ~disablePlugins.indexOf(name)
    tmp = await Promise.all tmp.map((name) => (new Promise (res, rej) =>
      for resolve in resolvers
        filename = resolve(name)
        if filename
          return res(pluginPath: filename, plugin: require(filename))
      rej new Error "Plugin #{name} not found in #{pluginPaths.join(', ')}"
      ).then (val) =>
        if (configSchema = val.plugin.configSchema)?
          if typeof configSchema == "function"
            configSchema(addToSchema, schema)
          else
            addToSchema configSchema
        return val
    )
    if plgs.plugins
      base[pluginProp] = tmp
    else
      conf[pluginProp] = tmp
  

  

  if o.watch
    o.filesToWatch = filesToWatch = []
    for k,v of require.cache
      filesToWatch.push k unless ~unwatchedModules.indexOf(k)
    o.watcher = watcher = chokidar.watch filesToWatch, 
      ignoreInitial: true
      awaitWriteFinish:
        stabilityThreshold: 100
        pollInterval: 100

    closed = null
    o.close ?= => o._close?()
    
    o._close = close = => closed ?= new Promise (resolve) =>
      for filepath in filesToWatch
        uncache(filepath,__filename) 
      await o.cancel(base) if o.cancel?
      watcher?.close()
      watcher = null
      resolve()

    invalidated = null
    o.invalidate ?= => o._invalidate?()
    o._invalidate = invalidate = (filename) => 
      return invalidated if invalidated?
      changed = o.plugins? or o.filesToWatch.length > 1
      if not changed and filename
        uncache(filename,__filename) 
        try
          conf = require confPath
          changed = o.hash != hash(conf)
      if changed
        invalidated = close()
          .catch (e) => console.log e
          .then => readConfig(o)

    watcher.on "all", (e, file) => invalidate(file)

  await statsDone if statsDone?
  
  if schema
    await validate2 conf
    unless isValid
      if o.watch
        return o
      else
        process.exit(1)
    else
      validate.setDefaults conf, schema, concat: o.concatArrays, ignore: ignoreDefaults
  if o.cb
    try
      await o.cb(base)
    catch e
      if o.watch
        console.log e
      else
        throw e
    if o.watch
      return o
    else
      return base
  return base

module.exports = (o) =>
  done = readConfig(o)
  done.catch o.catch if o.catch
  return done
module.exports.validate = validate