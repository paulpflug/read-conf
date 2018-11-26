{test} = require "snapy"
readConf = require "!./src/main.coffee"

test (snap) =>
  # short form
  # should yield "read-conf"
  snap promise: readConf("package"), filter: "resolved.config.name"


test (snap) =>
  # test folders prop
  # should yield someProp: "test", someProp3: "test"
  snap promise: readConf({
      name: "_testConf"
      folders: "./test"
  }), filter: "resolved.config"
  # should yield someProp: "test", someProp3: "test"
  snap promise: readConf({
      name: "_testConf"
      folders: ["./test"]
  }), filter: "resolved.config"
  
test (snap) =>
  # test extensions prop
  # should fail
  snap promise: readConf({
    name: "package"
    extensions: ["js"]
  })

test (snap) =>
  # test catch prop
  readConf({
    name: "invalid"
    catch: (e) => 
      # should yield the error
      snap obj: e
      return null
  })

test (snap) =>
  # test prop
  # should yield "read-conf"
  snap promise: readConf({
    name: "package"
    prop: "conf"
  }), filter: "resolved.conf.name"
  
test (snap) =>
  # test required
  # should pass with empty conf
  snap promise: readConf({
    name: "invalid"
    required: false
  }), filter: "resolved.config"

test (snap) =>
  # test filename
  # should yield "read-conf"
  snap promise: readConf({
    filename: "./package.json"
  }), filter: "resolved.config.name"

test (snap) =>
  # test invalid filename
  snap promise: readConf({
    filename: "./invalid"
  })