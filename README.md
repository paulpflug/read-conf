# read-conf

**Speed, functionality, simplicity - choose two.**

This fundamental tradeoff in programming is as true as always.
We are just better at hiding complexity - regular severe security flaws are a reminder of what we already hid away.

The only way we can improve this tradeoff is *clever program design*.

Over the last few years of programming I produced two very helpful guidelines
- separate by functionality
- aim for declarative programming

## Separation by functionality
Separation by functionality greatly improves extendability and understandability - thus maintainability.

You probably experienced the need for a major refactoring or even a complete rewrite at least once. And you will remember the large impact this had on your project - This happens when functionality isn't separated properly.

See [hook-up](https://github.com/paulpflug/hook-up) for a deeper description and a useful design pattern.

## Aim for declarative programming

Make your programs work with configuration files - the most common type of declarative programming.
They can be easily read, merged, diffed and shared.

Common settings of different projects can be easily extracted and maintained in one place.

This package is an allround tool for reading configuration files.

## Features

- reading ES7, coffeescript, typescript configuration files
- watch functionality
- schema validation
- doc generation from schema
- loads plugins and allows them to change the configuration schema


### Install
```sh
npm install --save read-conf
```

### Usage
```js
readConf = require("read-conf")
// readConf(options:Object):Promise
{config} = await readConf({name:"filename"})

// short form is allowed
packageJson = await readConf("package")
```

#### Options
Name | type | default | description
---:| --- | ---| ---
name | String | - | filename of the config
extensions | Array | `["js","json","coffee","ts"]` | extensions to look out for
folders | Array or String | `process.cwd()` | folder(s) to search in, can be relative to cwd or absolute
filename | String | - | absolute path to the config
default | Object | - | the config will be merged into this
assign | Object | - | this will be merged into the config
concatArrays | Boolean | false | concat arrays when merging
required | Boolean | true | will throw when no configuration file is found
schema | String or Object | - | File or Object used to validate configuration file
cb | Function | - | callback which is called with config obj
watch | Boolean | false | watches configuration file and dependencies for changes
cancel | Function | - | only with `watch`. Is called on file change
plugins | Boolean or Object | false | activate plugin management
prop | String | "config" | where to save config object
base | Object | {} | Object where config is saved to


#### Return value
`readConf` returns a Promise, which resolves with different values depending on availability of a `cb` function.
```js
base = new Class SomeClass

// without cb
readConf({name:"filename", base: base, prop:"conf"})
.then((value) => {
  value === base // true
  base.conf // content of file: "filename" 
  base.readConfig // Options object from above
})

// with cb
readConf({name:"filename", base: base, prop:"conf", cb: (value) => {
  value === base // true
  base.conf // content of file: "filename" 
  base.readConfig // Options object from above
  base.readConfig.hash // hash of config
}}).then((value) => {
  value // Options object from above
  value.base === base // true
  value.close // to close watcher and call cancel cb if watch == true
  value.watcher // chokidar filewatcher
})
```
#### Plugins
```js
// example
// config.js
module.exports = {
  plugins: ["somePlugin"] // plugins will be read in asynchronously 
}
// where you read config.js
conf = await readConf({name:"config",plugins:true})
conf.plugins[0].pluginPath // will have the resolved path of `somePlugin` package
conf.plugins[0].plugin // will have content of `somePlugin` package
```
Name | type | default | description
---:| --- | ---| ---
plugins.prop | String | "plugins" | Where to look for plugins in configuration
plugins.disableProp | String | "disablePlugins | Where to look for disable plugins in configuration
plugins.prepare | Function | - | Prepare configuration before loading plugins
plugins.paths | Array | [process.cwd()] | Where plugins are searched
#### Schema

```js
// example
// where you read config.js
conf = await readConf({name:"config",plugins:true,schema:{
  plugins: {
    type: Array,
    default: ["somePlugin"],
    
    // For documentation if default is not suitable
    _default: "Will load somePlugin",
    required: true, // will throw if not present
    desc: "Plugins to load", // For documentation
  },
  plugins$_item: String,
  propWithInvalidType: [Number, Function, RegExp],
  someObject: {
    type: Object

    // will not allow other children properties then specified in schema
    strict: true 
  },
  someObject$inSchema: Boolean
}})
// config.js
module.exports = {
  plguins: [], // will throw "plguins is no expected prop"
  propWithInvalidType: "", // will throw "invalid type"
  someObject: {

    // will throw someObject.notInSchema is no expected prop
    // because someObject is strict
    notInSchema: true 
  }
}
```
#### Generate documentation

```sh
# terminal
toDoc --help

# usage: toDoc (schema file)

# schema file is optional and defaults to "configSchema.[js|json|coffee|ts]"
# in "src/", "lib/", "/"
```
## License
Copyright (c) 2018 Paul Pflugradt
Licensed under the MIT license.
