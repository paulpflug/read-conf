{readMultiple} = require "./readConf"
merge = null
module.exports = (o) =>
  merge ?= require "webpack-merge"
  configs = await readMultiple(o)
  configs.unshift(o.default) if o.default?
  return merge configs