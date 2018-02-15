chai = require "chai"
should = chai.should()
validate = require "../src/validate.coffee"

schema = require "./schema.coffee"

describe "validate", =>
  it "should work", =>
    validate {test2:""}, schema
  it "should find missing entries", =>
    validate {}, schema
    .catch (e) =>
      e[0].should.equal "'test2' is missing"
  it "should find wrong types", =>
    validate {test2:{}}, schema
    .catch (e) =>
      e[0].should.equal "'test2' is of type 'Object'. Valid types are: ['String', 'Number']"
  it "should find unexpected entries", =>
    validate {test2:"",test3:1}, schema
    .catch (e) =>
      e[0].should.equal "'test3' is unexpected"
  it "should combine all of them", =>
    validate {test:"",test3:1}, schema
    .catch (e) =>
      e[0].should.equal "'test' is of type 'String'. Valid type is: 'Object'"
      e[1].should.equal "'test2' is missing"
      e[2].should.equal "'test3' is unexpected"  
