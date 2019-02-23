importCwd = null

module.exports = ({read, position}) =>

  read.hookIn position.init, (noop, o) =>
    {resolve} = o.path
    unless o.filename?
      unless o.name?
        throw new Error "read-conf: no name or filename for config was given" unless o.required == false
      {readdir, pathExists} = o.fs
      folders = o.folders || [process.cwd()]
      folders = [folders] unless Array.isArray(folders)
      exts = o.extensions || ["js","coffee","ts","json"]
      for folder in folders
        folder = resolve(folder)
        if await pathExists folder
          files = await readdir(folder)
          for ext in exts
            if ~files.indexOf(tmp = "#{o.name}.#{ext}")
              conf = tmp
              break
          break if conf
      o.filename = resolve(folder, conf) if conf
    else
      o.filename = resolve(o.filename)

  read.hookIn position.before, (noop, o) =>
    if o.filename?
      {stat} = o.fs
      stat(o.filename).then (stats) => 
        o.mtime = stats.mtimeMs
      .catch => 
        o.name ?= o.filename
        o.filename = null
      .then => 
        if o.filename and not importCwd?
          importCwd = require "import-cwd"
          importCwd.silent "coffee-script/register"
          importCwd.silent "coffeescript/register"
          importCwd.silent "ts-node/register"
          importCwd.silent "babel-register"
  
  
  read.hookIn (noop, o) =>
    if o.filename?
      try
        conf = require o.filename
      catch e
        if e.code == "MODULE_NOT_FOUND"
          throw new Error "read-conf: couldn't require '#{confPath}'" unless o.required == false
        else
          throw e
    else unless o.required == false
      throw new Error "read-conf: no file '#{o.name}' found"
    o.raw = conf or {}
    o.hash = o.util.hash(o.raw)