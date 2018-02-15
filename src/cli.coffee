args = process.argv.slice(2)

for arg,i in args
  arg = args[i]
  if arg[0] == "-"
    switch arg
      when '-h', "--help"
        console.log('usage: getDoc (schema file)')
        console.log('')
        console.log('schema file is optional and defaults to "configSchema.[js|json|coffee|ts]"')
        console.log('in "src/", "lib/", "/"')
        process.exit()
  else
    schemaFile = arg

importCwd = require "import-cwd"
importCwd.silent "coffee-script/register"
importCwd.silent "coffeescript/register"
importCwd.silent "ts-node/register"
importCwd.silent "babel-register"
unless schemaFile
  getSchemaFile = =>
    {stat,readdir,pathExists} = require "fs-extra"
    {resolve} = require "path"
    folders = ["./src","./lib",process.cwd()]
    exts = ["js","coffee","ts","json"]
    for folder in folders
      folder = resolve(folder)
      if await pathExists folder
        files = await readdir(folder)
        for ext in exts
          if ~files.indexOf(tmp = "configSchema.#{ext}")
            schemaFile = resolve(folder,tmp)
            break
        break if schemaFile
else
  getSchemaFile = Promise.resolve
getSchemaFile().then =>
  schema = require schemaFile
  {toDoc, getAdder} = require "./validate"
  if (configSchema = schema.configSchema)?
    addToSchema = getAdder(schema = {})
    if typeof configSchema == "function"
      configSchema(addToSchema, schema)
    else
      addToSchema configSchema
  console.log toDoc(schema)
.catch (e) => console.log e