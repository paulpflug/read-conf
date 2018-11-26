{test, getTestID} = require "snapy"
readConf = require "!./src/main.coffee"
fs = require "fs-extra"
file = => "./test/_pluginSchema#{getTestID()}.js"
write = (cleanUp, obj) =>
  fs.outputFile file(), "module.exports = {configSchema: #{obj}}"
  .then => cleanUp => fs.remove file()

test (snap) =>
  # test plugins.plugins
  # should yield the package name
  snap promise: readConf({
    name: "package"
    plugins:
      plugins: ["./package.json"]
  }), filter: "resolved.plugins.0.plugin.name"

test (snap) =>
  # test nested plugins
  # should yield the valid, valid2, and package name
  snap promise: readConf({
    name: "package"
    plugins:
      plugins: ["./test/_plugin.coffee"]
  }), transform: (obj) => obj.resolved.plugins.map (o) => o.plugin.name

test (snap, cleanUp) =>
  # test plugins with configSchema
  # should have test: valid
  await write cleanUp, "{test: {type: String, default: 'valid'}}"
  snap promise: readConf({
    required: false
    schema: {}
    plugins:
      plugins: [file()]
  }), filter: "resolved.config"

test (snap, cleanUp) =>
  # test plugins with configSchema function
  # should have test: valid
  await write cleanUp, "function(add){add({test: {type: String, default: 'valid'}})}"
  snap promise: readConf({
    required: false
    schema: {}
    plugins:
      plugins: [file()]
  }), filter: "resolved.config"

test (snap) =>
  # test plugins with schema default
  # should have package name
  snap promise: readConf({
    required: false
    schema: 
      plugins:
        type: Array
        default: ['./package.json']
    plugins: {}
  }), transform: (obj) => obj.resolved.config.plugins.map (o) => o.plugin.name

test (snap) =>
  # test plugins with schema default and disablePlugins
  # should have no plugin
  snap promise: readConf({
    required: false
    schema: 
      plugins:
        type: Array
        default: ['./package.json']
      disablePlugins:
        type: Array
        default: ['./package.json']
    plugins: {}
  }), transform: (obj) => obj.resolved.config.plugins

test (snap) =>
  # test plugins.prepare
  # should have package name
  snap promise: readConf({
    required: false
    plugins: prepare: (conf) => conf.plugins = ["./package.json"]
  }), transform: (obj) => obj.resolved.config.plugins.map (o) => o.plugin.name