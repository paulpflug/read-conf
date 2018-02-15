isProd = process.env?.NODE_ENV == "production"

module.exports =
  verbose:
    type: Number
    default: 1
    desc: "Level of logging"
  
  index: 
    type: String
    default: "index.html"
    desc: "Default file to serve when in folder"
  
  base: 
    type: String
    default: ""
    desc: "namespace for the server e.g. /leajs"
  
  listen: 
    type: Object
    default: {}
    desc: "Listen object for httpServer"

  listen$host:
    type: String
    default: if isProd then "localhost" else null
    _default: "if inProduction then \"localhost\" else null"
    desc: "Hostname for listening"

  listen$port:
    types: [Object, Number]
    default: if process.env?.LISTEN_FDS then fd: 3 else 8080
    _default: "if process.env.LISTEN_FDS then {fd: 3} else 8080"
    desc: "Port or socket to listen to"

  plugins:
    type: Array
    default: [
      "leajs-files"
      "leajs-folders"
      "leajs-encoding"
      "leajs-cache"
      "leajs-locale"
      "leajs-eventsource"
      "leajs-redirect"
    ]
    desc: "Leajs plugins to load"

  plugins$_item:
    type: String
    desc: "Package name or filepath (absolute or relative to cwd) of plugin"

  disablePlugins:
    type: Array
    desc: "Disable some of the default plugins"

  disablePlugins$_item:
    type: String
    desc: "Package name or filepath (absolute or relative to cwd) of plugin"

  respond:
    types: [Function, Array]
    desc: "Custom respond function for quick debugging or testing"