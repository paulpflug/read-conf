fs = require "fs-extra"
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

parse = (o) =>
  if typeof o == "string" or o instanceof String
    o = name: o 
  else if not o?.name?
    throw new Error "read-conf: no name for config was given"
  folders = o.folders || [process.cwd()]
  folders = [folders] unless Array.isArray(folders)
  exts = o.extensions || ["js","coffee","ts","json"]
  return [o.name, folders, exts]

module.exports = (o) =>
  [name, folders, exts] = parse(o)
  for folder in folders
    folder = path.resolve(folder)
    files = await fs.readdir(folder)
    for ext in exts
      if ~files.indexOf(tmp = "#{name}.#{ext}")
        conf = tmp
        break
    break if conf
  throw new Error "read-conf: no file '#{name}' found" unless conf 
  confPath = path.resolve(folder, conf)
  try
    conf = require confPath
  catch
    throw new Error "read-conf: couldn't require '#{confPath}'"
  stats = await fs.stat confPath
  conf.mtime = stats.mtimeMs
  return conf

module.exports.readMultiple = (o) =>
  confs = []
  [name, folders, exts] = parse(o)
  for folder in folders
    folder = path.resolve(folder)
    files = await fs.readdir(folder)
    for ext in exts
      if ~files.indexOf(tmp = "#{name}.#{ext}")
        confPath = path.resolve(folder, tmp)
        try
          conf = require confPath
        catch
          throw new Error "read-conf: couldn't require '#{confPath}'"
        confs.push conf
  return confs