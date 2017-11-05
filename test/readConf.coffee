chai = require "chai"
should = chai.should()
path = require "path"
fs = require "fs-extra"
readConf = require "../src/readConf.coffee"

confName = (name) => path.resolve(__dirname,name)

describe "readConf", =>
  it "should work", =>
    config = await readConf 
      name: "testConf"
      folders:__dirname
      default:
        someProp: "test1"
        someProp2: "test2"
    config.someProp.should.equal "test"
    config.someProp2.should.equal "test2"
    should.exist config.mtime
  it "should work with short form", =>
    config = await readConf "package"
    config.name.should.equal "read-conf"
  it "should work with watch", (done) =>
    i = 0
    closer = null
    filename = confName("watchConf.json")
    cb = (conf) =>
      try
        if i == 0
          i++
          conf.prop.should.equal "value"
          fs.writeJson filename, prop: "value2"
        else if i == 1
          conf.prop.should.equal "value2"
          closer?()
          fs.writeJson filename, prop: "value" 
          .then done
      catch e
        await fs.writeJson filename, prop: "value"
        closer?()
        done e
    readConf 
      name:"watchConf"
      watch: true
      cb: cb
      folders:__dirname
    .then (close) => closer = close
    return null
  it "should work with cancel", (done) =>
    closer = null
    canceled = false
    filename = confName("watchConf.json")
    cb = (conf) =>
      if canceled
        closer()
        done()
      else
        fs.writeJson filename, prop: "value" 
    readConf 
      name:"watchConf"
      watch: true
      cb: cb
      folders:__dirname
      cancel: => canceled = true
    .then (close) => closer = close
    return null
  it "should not call cancel when busy", (done) =>
    closer = null
    canceled = false
    filename = confName("watchConf.json")
    cb = (conf) =>
      if canceled
        closer()
        done()
      else
        fs.writeJson filename, prop: "value" 
    i = 0
    readConf 
      name:"watchConf"
      watch: true
      cb: cb
      folders:__dirname
      cancel: => new Promise (resolve) =>
        i.should.equal 0
        i++
        canceled = true
        setTimeout (=>
          resolve()
          ),50
        fs.writeJson filename, prop: "value"
    .then (close) => closer = close
    return null