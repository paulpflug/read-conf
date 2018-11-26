validate = require("./validate")
module.exports = ({run, position}) =>
  run.hookIn position.before-1, (base, o) =>
    if (schema = o.schema)?
      if o.util.isString(schema)
        schema = require schema
      o._schema ?= []
      obj = o._schema[base._readConfigIndex] = 
        schema: schema
        add: validate.getAdder(schema)
        ignore: ignore = []
        validate: (conf) =>
          conf = base[o.prop or "config"]
          validate conf, schema, isNormalized:true, ignore: ignore
          .then =>
            validate.setDefaults conf, schema, concat: o.concatArrays, ignore: ignore
          .catch (problems) =>
            if problems instanceof Error
              throw problems
            else
              console.error chalk.red.bold "\n\nInvalid configuration\n"
              console.error chalk.red("File: ")+chalk.underline("#{confPath}\n")
              console.error chalk.red("Problems:")
              console.error chalk.dim " - " + problems.join("\n - ") + "\n\n"
              process.exit(1) unless o.watch
              throw "Invalid configuration"


  
  run.hookIn position.after+1, (base, o) =>
    if (schema = o._schema?[base._readConfigIndex])?
      schema.validate()
          