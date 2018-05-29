{test} = require "snapy"
path = require "path"
fs = require "fs-extra"
readConf = require "!./src/readConf.coffee"

confName = (name) => path.resolve(__dirname,name)

test (snap) =>
  snap promise: readConf({
      name: "_testConf"
      folders: "./test"
      default:
        someProp: "test1"
        someProp2: "test2"
      assign:
        someProp3: "test3"
  }), filter: "resolved.config"
  # short form
  snap promise: readConf("package"), filter: "resolved.config.name"
  # with schema
  snap promise: readConf({
      name: "_testConf"
      folders:"./test"
      schema:
        someProp: 
          type: String
          default:"test1"
        someProp2: 
          type: String
          default:"test2"
        someProp3: String
      assign:
        someProp3: "test3"
  }), filter: "resolved.config"

test (snap, cleanUp) =>
  filename = confName("watchConf1.json")
  await fs.writeJson filename, prop: "value"
  cleanUp => fs.unlink filename
  i = 0
  readConf 
    name:"watchConf1"
    watch: true
    folders:__dirname
    cb: ({config, readConfig}) =>
      if i++ == 0
        cleanUp => readConfig.close()
        snap obj: config
        fs.writeJson filename, prop: "value2"
      else
        snap obj: config

test (snap, cleanUp) =>
  filename = confName("watchConf2.json")
  await fs.writeJson filename, prop: "value2"
  cleanUp => fs.unlink filename
  readConf 
    name:"watchConf2"
    watch: true
    folders:__dirname
    cancel: (obj) =>
      cleanUp => obj.readConfig.close()
      snap obj: obj.config
    cb: => fs.writeJson filename, prop: "value4"
