chokidar = uncache = null

module.exports = ({read, run, cleanUp, position}) =>
  read.hookIn position.before, (o) =>
    if o.watch 
      chokidar = require "chokidar"
      uncache = require "recursive-uncache"
      unless o.unwatchedModules?
        arr = o.unwatchedModules = []
        for k,v of require.cache
          arr.push k
  run.hookIn position.during+1, (base, o) =>
    if o.watch
      arr = o.filesToWatch ?= []
      arr2 = o.unwatchedModules
      for k,v of require.cache
        arr.push k if (not ~arr.indexOf(k)) and (not ~arr2.indexOf(k))
         
  uncacheAll = (o) =>
    for filepath in o.filesToWatch
      uncache(filepath) 

  run.hookIn position.after, (base, o) =>
    if o.watch
      if (watcher = o.watcher)?
        watcher.add o.filesToWatch
      else
        o.watcher = chokidar.watch o.filesToWatch, 
          ignoreInitial: true
          awaitWriteFinish:
            stabilityThreshold: 100
            pollInterval: 100

        o.invalidate = (filename) => 
          if o.state.invalidating
            if o.state.closing
              if filename
                uncache(filename)
              else
                uncacheAll(o)
              return o.state.invalidating
          if filename?
            changed = o.plugins? or o.filesToWatch.length > 1
            if not changed and o.filename
              uncache(filename) 
              try
                conf = require o.filename
                changed = o.hash != o.util.hash(conf)
          else
            uncacheAll(o)
            changed = true
          if changed
            return o.state.invalidating = o.state.cleaning or o.cleanUp()
              .catch (e) => console.log e
              .then => o.read()
              .catch (e) => console.log e
              .then => 
                o.state.invalidating = false
                return o
          else
            return Promise.resolve(o)

        o.watcher.on "all", (e, file) => o.invalidate(file)
  
  cleanUp.hookIn (o) =>
    if (watcher = o.watcher)?
      uncacheAll(o)
      watcher.close()
      o.watcher = null
