{readMultiple} = require "./readConf"
merge = null
module.exports = (o) =>
  merge ?= require "webpack-merge"
  o ?= {}
  o.name ?= "webpack.conf"
  configs = await readMultiple(o)
  configs.unshift(o.default) if o.default?
  return merge configs