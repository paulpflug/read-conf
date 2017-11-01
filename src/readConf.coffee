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

module.exports = (o) =>
  if typeof o == "string" or o instanceof String
    o = name: o 
  else if not o?.name?
    throw new Error "read-conf: no name for config was given"
  folders = o.folders || [process.cwd()]
  folders = [folders] unless Array.isArray(folders)
  exts = o.extensions || ["js","coffee","ts","json"]
  for folder in folders
    files = await fs.readdir(folder)
    for ext in exts
      if ~files.indexOf(tmp = "#{o.name}.#{ext}")
        conf = tmp
        break
    break if conf
  throw new Error "read-conf: no file '#{o.name}' found" unless conf 
  confPath = path.resolve(folder, conf)
  try
    conf = require confPath
  catch
    throw new Error "read-conf: couldn't require '#{confPath}'"
  stats = await fs.stat confPath
  conf.mtime = stats.mtimeMs
  return conf