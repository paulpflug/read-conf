{test} = require "snapy"
validate = require "../src/validate.coffee"

schema = require "./_schema.coffee"

test (snap) =>
  # should work
  snap promise: validate {test2:""}, schema
  # should have missing
  snap promise: validate {}, schema
  # should have invalid type
  snap promise: validate {test2:{}}, schema
  # should find unexpected entry
  snap promise: validate {test2:"",test3:1}, schema
  # should find 3 errors
  snap promise: validate {test:"",test3:1}, schema