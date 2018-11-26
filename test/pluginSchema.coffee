{test} = require "snapy"
readConf = require "!./src/main.coffee"

test (snap) =>
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

