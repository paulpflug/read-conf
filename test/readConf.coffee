chai = require "chai"
should = chai.should()

readConf = require "../src/readConf.coffee"

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
  it "should be able to read multiple", =>
    config = await readConf.readMultiple name: "package", folders: ["./","./test"]
    config[0].name.should.equal "read-conf"
    config[1].someProp.should.equal "someVal"
  it "should be able to read multiple and merge", =>
    config = await readConf.readMultipleAndMerge name: "package", folders: ["./","./test"]
    config.name.should.equal "read-conf"
    config.someProp.should.equal "someVal"