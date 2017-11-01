# read-conf
reads a config file. 

Using if available:
- babel-register
- coffeescript/register
- coffee-script/register
- ts-node/register

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
// short form is allowed
packageJson = await readConf("package")
```

#### Options
Name | type | default | description
---:| --- | ---| ---
name | String | - | (required) filename of the config
extensions | Array | `["js","json","coffee","ts"]` | extensions to look out for
folders | Array or String | `process.cwd()` | folder(s) to search in, can be relative to cwd or absolute
default | Object | - | Object, the config will be merged into if given

#### Helper
```js
// to read all found configuration files
arrayOfConf = readConf.readMultiple({name:"filename",folders:["./","./someFolder"]})

// to also merge them
conf = readConf.readMultipleAndMerge({name:"filename",folders:["./","./someFolder"]})

// to read multiple webpack configs and merge them
// npm install webpack-merge is required
readWebpackConf = require("read-config/webpack")
webpackConf = readWebpackConf({
  name: "webpack.conf",
  folders: ["./","./someFolder"],
  default: someDefaultWebpackConf
  })
```

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
