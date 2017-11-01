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
```

#### Options
Name | type | default | description
---:| --- | ---| ---
name | String | - | (required) filename of the config
extensions | Array | `["js","json","coffee","ts"]` | extensions to look out for
folders | Array or String | `process.cwd()` | folder(s) to search in

## License
Copyright (c) 2017 Paul Pflugradt
Licensed under the MIT license.
