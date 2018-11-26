hookUp = require "hook-up"
plugins = [
  "Util"
  "Read"
  "Iterate"
  "Plugins"
  "Watch"
  "Schema"
]
toClose = []
close = =>
    await Promise.all(toClose.map (o) => o.close())
    process.exit(1)

process.on "SIGINT", close
process.on "SIGTERM", close
process.on "SIGHUP", close

module.exports = (o = {}) =>

  {isString} = require("./pluginUtil")
  o = {name: o} if isString(o)

  o.fs = require "fs-extra"
  o.path = require "path"

  hookUp o,
    actions: ["read", "run", "cleanUp"]
    catch: read: o.catch
    state:
      read: "running"
      cleanUp: "cleaning"
  
  
  for plugin in plugins
    require("./plugin"+plugin)(o)
  
  o.read.hookIn o.position.init, =>
    toClose.push o unless ~(i = toClose.indexOf(o))
  o.cleanUp.hookIn o.position.end, =>
    toClose.splice(i,1) if ~(i = toClose.indexOf(o))

  o._getBase = =>
    if o.iterate
      return (o.bases or [])
    else
      return (o.bases or [])[0]

  o.close = =>
    await o.cleanUp()
    if o.onClose
      try
        await o.onClose(o._getBase()) 
      catch e
        console.log e
    return o._getBase()

  return o.read()
    .catch (e) => 
      if o.watch
        console.log e
      else
        await o.close()
        throw e
    .then =>
      if o.watch
        return o
      else
        await o.close()
        return o._getBase()

module.exports.validate = require "./validate"