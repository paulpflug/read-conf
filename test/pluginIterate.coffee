{test} = require "snapy"
readConf = require "!./src/main.coffee"

test (snap) =>
  # test default
  # should have someProp2: "test", but no someProp "should not be there"
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    default:
      someProp: "should not be there"
      someProp2: "test"
  }), filter: "resolved.config"


test (snap) =>
  # test assign
  # should have someProp: "test2"
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    assign:
      someProp: "test2"
  }), filter: "resolved.config"

test (snap) =>
  # test base
  # should yield "test2"
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    base:
      someProp: "test2"
  }), filter: "resolved.someProp"
  # should yield "test2"
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    base: =>
      someProp: "test2"
  }), filter: "resolved.someProp"

test (snap) =>
  # test iterate
  # should have someProp: "test2"
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    iterate:[
      {test: "test1"}
      {test: "test2"}
    ]
  }), transform: (obj) =>
    obj.resolved.map (base) => base.config

test (snap) =>
  # test iterate and base
  # should have 0,1
  i = 0
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    base: => someProp: i++
    iterate:[
      {test: "test1"}
      {test: "test2"}
    ]
  }), transform: (obj) =>
    obj.resolved.map (base) => base.someProp

test (snap) =>
  # test iterate, default and assign
  # should have 0,1
  i = 0
  snap promise: readConf({
    filename: "./test/_testConf.coffee"
    iterate:[
      {test1: "test1"}
      {test3: "test2",test2: "test2"}
    ]
    default: {
      test1: "test"
    }
    assign: {
      test2: "test"
    }
  }), transform: (obj) =>
    obj.resolved.map (base) => base.config

test (snap) =>
  # test cb
  # should have someProp: "test" and someProp3: "test"
  readConf({
    filename: "./test/_testConf.coffee"
    cb: (base) => snap obj:base.config
  })

test (snap) =>
  # test cleanUp
  readConf({
    required: false
    onClose: (base) =>
      # should have 2
      snap obj: ++base.i
    cb: (base) =>
      base.i = 0
      # should have 1
      => snap obj: ++base.i
  }).then (base) =>
    # should have 3
    snap obj: ++base.i