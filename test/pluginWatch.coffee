{test} = require "snapy"
path = require "path"
fs = require "fs-extra"
readConf = require "!./src/main.coffee"

confName = (name) => path.resolve(__dirname,name)

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
        # should have value
        snap obj: config
        fs.writeJson filename, prop: "value2"
      else
        #should have value2
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
      obj.readConfig.watcher.close()
      # should have value2
      snap obj: obj.config
    cb: => 
      fs.writeJson filename, prop: "value4"
      .then => new Promise (resolve) => setTimeout resolve, 200
