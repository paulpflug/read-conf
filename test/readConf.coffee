chai = require "chai"
should = chai.should()
path = require "path"
fs = require "fs-extra"
readConf = require "../src/readConf.coffee"

confName = (name) => path.resolve(__dirname,name)

describe "readConf", =>
  it "should work", =>
    {config, readConfig} = await readConf 
      name: "testConf"
      folders:__dirname
      default:
        someProp: "test1"
        someProp2: "test2"
      assign:
        someProp3: "test3"
    config.someProp.should.equal "test"
    config.someProp2.should.equal "test2"
    config.someProp3.should.equal "test3"
    should.exist readConfig.mtime
  it "should work with short form", =>
    {config} = await readConf "package"
    config.name.should.equal "read-conf"
  it "should work with schema", =>
    {config, readConfig} = await readConf 
      name: "testConf"
      folders:__dirname
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
    config.someProp.should.equal "test"
    config.someProp2.should.equal "test2"
    config.someProp3.should.equal "test3"
    should.exist readConfig.mtime
  it "should work with watch", => new Promise (resolve) =>
    i = 0
    filename = confName("watchConf1.json")
    await fs.writeJson filename, prop: "value"
    readConf 
      name:"watchConf1"
      watch: true
      folders:__dirname
      cb: ({config, readConfig}) =>
        try
          if i == 0
            i++
            config.prop.should.equal "value"
            fs.writeJson filename, prop: "value2"
          else if i == 1
            config.prop.should.equal "value2"
            throw null
        catch e
          readConfig.close()
          fs.unlink filename
          resolve e
      
  it "should work with cancel", => 
    resolve = null
    prom = new Promise (res) => resolve = res
    filename = confName("watchConf2.json")
    await fs.writeJson filename, prop: "value2" 
    {close} = await readConf 
      name:"watchConf2"
      watch: true
      folders:__dirname
      cancel: resolve
      cb: => new Promise (res) =>
        fs.writeJson filename, prop: "value4"
        setTimeout res, 150
    
    return prom.then close
      .then => fs.unlinkSync filename

  it "should not call cancel when busy", => new Promise (resolve) =>
    canceled = false
    filename = confName("watchConf3.json")
    await fs.writeJson filename, prop: "value3"
    readConf 
      name:"watchConf3"
      watch: true
      cb: ({readConfig}) => new Promise (res) =>
        if canceled
          readConfig.close()
          await fs.unlink(filename)
          resolve()
        else
          await fs.writeJson filename, prop: "value6"
          setTimeout res, 150
      folders:__dirname
      cancel: => 
        canceled = true
        fs.writeJson filename, prop: "value9"