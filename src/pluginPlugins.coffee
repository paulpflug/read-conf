resolveFrom = require "resolve-from"
{dirname} = require "path"
module.exports = ({run, position}) =>
  run.hookIn position.before, (base, o) =>
    if (plgs = o.plugins)?
      conf = base[o.prop or "config"]
      pluginProp = plgs.prop or "plugins"
      disableProp = plgs.disableProp or "disablePlugins"
      if (schemaObj = o._schema?[base._readConfigIndex])?
        schema = schemaObj.schema
        for prop in [pluginProp, disableProp]
          if (def = schema[prop]?.default)?
            arr = conf[prop] ?= []
            for str in def
              arr.push str unless ~arr.indexOf(str)
        # processed plugins are saved over config plugins
        # so they shouldn't get validated
        if schema[pluginProp]?.default? or conf[pluginProp]?
          schemaObj.ignore.push pluginProp
      if (prep = plgs.prepare)?
        prep(conf, base)

      pluginPaths = plgs.paths or [process.cwd()]

      plugins = plgs.plugins or conf[pluginProp]
      disablePlugins = plgs.disablePlugins or conf[disableProp]
      found = []

      find = (name, paths) =>
        return Promise.resolve() if disablePlugins? and ~disablePlugins.indexOf(name)
        return Promise.resolve() if ~found.indexOf(name)
        return new Promise (resolve, reject) =>
          for path in paths
            filename = resolveFrom.silent(path, name)
            if filename
              found.push name
              return resolve(pluginPath: filename, plugin: require(filename)) 
          reject new Error "Plugin #{name} not found in #{paths.join(', ')}"

      getPlugins = (plugins, plg) => 
        if plg?
          paths = [dirname(plg.pluginPath)]
          processed = [plg]
        else
          paths = pluginPaths
          processed = []
        if plugins?
          for name in plugins
            processed.push find(name, paths).then (val) =>
              return unless val?
              {plugin} = val
              if schemaObj? and (configSchema = plugin.configSchema)?
                if typeof configSchema == "function"
                  configSchema(schemaObj.add, schema)
                else
                  schemaObj.add configSchema
                delete plugin.configSchema
              if (tmpPlgs = plugin.plugins)?
                delete plugin.plugins
                return getPlugins(tmpPlgs, val)
              else
                return val
        return Promise.all(processed)



      reduce = (arr) =>
        tmpArr = []
        if arr?
          for item in arr
            if Array.isArray(item)
              Array::push.apply(tmpArr, reduce(item))
            else
              tmpArr.push item if item?
        return tmpArr

      plugins = await getPlugins(plugins).then reduce
      if plgs.plugins
        base[pluginProp] = plugins
      else
        conf[pluginProp] = plugins
      


