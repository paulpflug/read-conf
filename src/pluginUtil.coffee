isString = (o) => typeof o == "string" or o instanceof String
{createHash} = require "crypto"
hash = (obj) => createHash("sha1").update(JSON.stringify(obj, (key,val) =>
  if typeof val == "function"
    val.toString()
  else
    val
)).digest("base64")

module.exports = (o) =>
  o.util = isString: isString, hash: hash

module.exports.isString = isString
