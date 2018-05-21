
allTypes = [
  String
  Number
  Array
  Object
  Function
  RegExp
  Boolean
]
toStr = Object::toString
_is = {}
__is = {Boolean: (bool) => typeof bool == "boolean" }

iterate = (obj, cb) => 
  keys = Object.keys(obj).sort()
  for key in keys
    cb(key, obj[key])

getChecker = (name) => (o) => toStr.call(o) == "[object #{name}]"

allTypes.forEach ({name}) =>
  __is[name] ?= _is[name.toLowerCase()] = getChecker(name)

normalize = (schema) =>
  for k,v of schema
    if v.type
      v.types = types = v.type 
    else unless (types = v.types)?
      v = schema[k] = {types: (types = [v])}
    unless Array.isArray(types)
      v.types = [types]
    unless v._normalized
      v._normalized = true
      if v.types?
        v._types = v.types.map (type) => 
          throw new Error "Schema invalid. #{type} is no Type." unless (tmp = __is[type.name])
          return tmp
  return schema

getRequired = (schema) =>
  required = {}
  iterate schema, (k,v) => required[k] = true if v.required
  return required

getTypeNames = (types) => types.map(({name}) => name)

getTypeError = (obj, schema) =>
  for name, checker of __is
    break if checker(obj)
  str = "of type '#{name}'. Valid type"
  if (types = schema.types).length > 1
    str += "s are: ['" + getTypeNames(types).join("', '") + "']"
  else
    str += " is: '#{types[0].name}'"
  return str

isValid = (obj, schema) =>
  return true unless (types = schema._types)
  types.some (checker) => checker obj

allTrue = (arr) =>
  for val in arr
    return false if val == false
  return true

getKey = (key, newKey) =>
  return newKey unless key
  return key+"$"+newKey

realKey = (key) =>
  lastChar = ""
  str = ""
  for char in key
    if char == "$"
      newChar = "."
    else if char == "_" and lastChar == "$"
      newChar = "$"
    else
      newChar = char
    lastChar = char
    str += newChar
  return str

module.exports = (obj, schema, {isNormalized, ignore = []} = {} ) => new Promise (resolve, reject) =>

  normalize(schema) unless isNormalized
  required = getRequired(schema)
  problems = {}
  addProblem = (key, msg) => problems[realKey(key)] = msg
  walk = (curr, key, currSchema) =>
    delete required[key]
    return true if ~ignore.indexOf(key)
    return false unless currSchema?
    return true unless curr?
    unless isValid(curr, currSchema)
      addProblem key, getTypeError(curr, currSchema)
    if _is.array(curr)
      newSchema = schema[newKey = getKey(key, "_item")]
      if newSchema?
        for item in curr
          walk item, newKey, newSchema
    else if _is.object(curr)
      isStrict = currSchema.strict
      iterate curr, (k, item) =>
        if not walk(item, (newKey = getKey(key,k)), schema[newKey]) and isStrict
          addProblem newKey, "unexpected"
        else unless isStrict
          walk(item, (newKey = getKey(key,"_item")), schema[newKey])
    return true
        
  walk obj, "", {_types: [_is.object], strict: true}
  iterate required, (k) => addProblem k, "missing"
  if (keys = Object.keys(problems)).length > 0
    reject(keys.sort().map((key) => "'#{key}' is #{problems[key]}" ))
  else
    resolve()


module.exports.getAdder = (schema) => 
  normalize(schema)
  return (newSchema, merge) =>
    for k,v of normalize(newSchema)
      if merge and (v2 = schema[k])
        for k3,v3 of v
          v2[k3] = v3
      else
        schema[k] = v
    return schema

module.exports.setDefaults = (obj, schema, {concat, ignore = []} = {}) =>
  iterate schema, (k,v) =>
    if (def = v.default)? and not ~ignore.indexOf(k)
      {parent, prop} = k.split("$").reduce ((acc,curr) =>
        val = acc.parent = acc.parent[acc.prop]
        unless (val)?
          throw new Error "couldn't set default value on #{realKey(k)}"
        acc.prop = curr
        return acc
      ), {parent: {1: obj}, prop:1}
      
      unless (val = parent[prop])?
        parent[prop] = def
      else if concat and Array.isArray(val) and Array.isArray(def)
        for item in def
          val.push item unless ~val.indexOf(item)
      

module.exports.toDoc = (schema, type) =>
  lines = ["```js","module.exports = {"]
  indention = "  "
  indent = 1
  getIndent = => indention.repeat(indent)
  normalize(schema)
  keys = Object.keys(schema)
  if keys.length < 5
    lines.push "\n  // …"
  {push} = Array::
  concat = (arr) => push.apply(lines, arr)
  ignore = []
  parent = ""
  iterate schema, (k,v) =>
    return if ~ignore.indexOf(k)
    # end of block
    if parent and not k.startsWith(parent+"$")
      parent = ""
      indent--
      lines.push ""
      lines.push getIndent() + "},"
    ind = getIndent()
    names = getTypeNames(v.types)
    getTypes = (long, schem) =>
      if schem
        _n = getTypeNames(schem.types)
      else
        _n = names
      types = if _n.length == 1 then _n[0] else "["+_n.join(", ")+ "]"
      if long
        types = if _n.length == 1 then "type: "+types else "types: "+types
      return types
    
    def = v.default unless v._default?
    def ?= null
    def = JSON.stringify(def)+","
    typeAbove = def.length > 20

    if ~names.indexOf("Object") or ~names.indexOf("Array")
      dynamic = []
      children = keys.filter (key) =>
        if key.startsWith(k+"$")
          if key.startsWith(k+"$_item")
            dynamic.push(key)
            return false
          return true
        return false
      if children.length > 0
        if def == "{},"
          def = "{"
          typeAbove = true
          parent = k
          indent++
        #else if ~names.indexOf("Object")
    # newLine
    lines.push ""

    # description above
    if (desc = v.desc?.split("\n"))?
      concat desc.map (str) => ind + "// " + str
    required = if v.required then "(required) " else ""

    # type above
    lines.push ind + "// " + required + getTypes(true) if typeAbove
    
    # default above when _default is present
    lines.push ind + "// Default: "+v._default if v._default
    
    # dynamic above
    if dynamic?.length > 0
      for dyn in dynamic
        tmpval = schema[dyn]
        ignore.push dyn
        dynName = "$" + realKey(dyn.replace(k+"$_item","item"))
        lines.push ind + "// #{dynName} (" + getTypes(false, tmpval)+") " + (tmpval.desc or "")

    # value
    k = k.replace(parent+"$","") if parent
    val = ind + realKey(k) + ": " + def 
    unless typeAbove
      val += " // " + required + getTypes(false)
    lines.push val
  lines.push "\n  // …\n"
  lines.push "}"
  lines.push "```"
  return lines.join("\n")