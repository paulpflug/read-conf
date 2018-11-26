mergeOptions = require "merge-options"
module.exports = ({read, run, cleanUp, position}) =>
  read.hookIn position.after, (o) =>
    unless o.state.closing
      if (iterate = o.iterate)?
        if o.util.isString(iterate)
          arr = o[iterate]
        else
          arr = iterate
      unless arr?
        arr = [{}]
      else unless Array.isArray(arr)
        arr = [arr]
      o.bases = []
      o._cleanUps = []
      mergeConfig = concatArrays: o.concatArrays
      mergeArgs = [o.raw, null]
      mergeArgs.unshift(o.default) if hasDefault = (o.default?)
      mergeArgs.push o.assign if o.assign?
      runners = []
      for obj in arr
        mergeArgs[1+hasDefault] = obj
        conf = mergeOptions.apply(mergeConfig, mergeArgs)
        if (base = o.base)? and typeof base == "function"
          base = base()
        base ?= {}
        base[o.prop or "config"] = conf
        base.readConfig = o
        base._readConfigIndex = o.bases.length
        o.bases.push base
        runners.push o.run(base)
      Promise.all(runners)

  cleanUp.hookIn position.before, (o) =>
    if o.cancel? and o.bases? and o.state.running
      Promise.all(o.bases.map (tmpBase) => o.cancel(tmpBase)).then o.state.running
  
  run.hookIn position.end-1, (base, o) =>
    if o.cb? and not o.state.closing
      try
        val = await o.cb(base)
      catch e
        if o.watch
          console.log e
          o.cancel(base)
        else
          throw e
      o._cleanUps.push val if val? and typeof val == "function"
  
  cleanUp.hookIn (o) =>
    if (cleanUps = o._cleanUps)? and cleanUps.length > 0
      Promise.all(cleanUps)
      .then (cleanUps) =>
        Promise.all cleanUps.map (cleanUp) => 
          cleanUp() if typeof cleanUp == "function"
      .then => o._cleanUps = null


