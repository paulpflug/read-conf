# read-conf
reads a config file. 

Using if available:
- babel-register
- coffeescript/register
- coffee-script/register
- ts-node/register

Can also watch a config file and all of its dependencies using `chokidar` and `recursive-uncache`.

### Install
```sh
npm install --save read-conf
```

### Usage
```js
readConf = require("read-conf")
// readConf(options:Object):Promise
conf = await readConf({name:"filename"})
conf.mtime // contains modified time of config file
conf.hash // contains hash of config object
// short form is allowed
packageJson = await readConf("package")

// has sophisticated watch functionality 
unwatch = await readConf({name: "package",watch: true, cb: (conf) => {
  // config has changed 
  // can be async
  return await someStartup(conf)
}, cancel: () => {
  // config has changed, but last cb didn't return yet
  // cb will be called again, once this functions returns
  // implement some sort of sleep to wait for other files to change
  await Promise((resolve) => {setTimeout(resolve, 100)})
  // can be async
  return await someTearDown()
}})
unwatch() // once you want to cancel watching

// cb syntax also possible without watch
unwatch = await readConf({name: "package",watch: false, cb: (conf) => {

}})
unwatch() // empty function, save to call
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
cb | Function | - | callback which is called with config obj
watch | Boolean | false | uses watch
cancel | Function | - | only with `watch`. Is called on file change when cb is still busy
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
