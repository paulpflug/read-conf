chai = require "chai"
should = chai.should()

readConf = require "../src/readConf.coffee"

describe "readConf", =>
  it "should work", =>
    config = await readConf name: "testConf", folders:__dirname
    config.someProp.should.equal "test"
    should.exist config.mtime