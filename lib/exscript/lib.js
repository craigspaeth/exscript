//
// A JS library used to implement Elixir/Erlang standard library or language
// features that don't translate very cleanly 1:1.
//
const ExScript = {}

// Namespace for user-land modules
ExScript.Modules = {}
ExScript.Modules.JS = {
  window: () => window
}
ExScript.Modules.IO = {
  puts: window.console.log,
  inspect: window.console.debug
}

// Data Types
ExScript.Types = {}
ExScript.Types.Tuple = class Tuple extends Array {}

// Standard library

// Atom
ExScript.Modules.Atom = {}
ExScript.Modules.Atom.to_string = atom => String(atom).slice(7, -1)

// Enum
ExScript.Modules.Enum = {}
ExScript.Modules.Enum.map = (e, ittr) => Array.prototype.map.call(e, ittr)
ExScript.Modules.Enum.reduce = (enumerable, arg2, arg3) => {
  const reducer = arg3 || arg2
  const initVal = arg3 ? arg2 : enumerable[0]
  const callback = (acc, val, i) => reducer(val, acc)
  return Array.prototype.reduce.call(enumerable, callback, initVal)
}
ExScript.Modules.Enum.join = (e, char) => Array.prototype.join.call(e, char)
ExScript.Modules.Enum.at = (e, index) => e[index]

// Map
ExScript.Modules.Map = {}
ExScript.Modules.Map.put = (map, key, val) => {
  map[key] = val
  return map
}

// List
ExScript.Modules.List = {}
ExScript.Modules.List.first = list => list[0]

// Keyword
ExScript.Modules.Keyword = {}
ExScript.Modules.Keyword['keyword?'] = list =>
  list && list[0] instanceof ExScript.Types.Tuple

// Kernel
ExScript.Modules.Kernel = {}
ExScript.Modules.Kernel.is_atom = val => typeof val === 'symbol'
ExScript.Modules.Kernel.is_binary = val => typeof val === 'string'
ExScript.Modules.Kernel.is_bitstring = val => typeof val === 'string'
ExScript.Modules.Kernel.is_boolean = val => typeof val === 'boolean'
ExScript.Modules.Kernel.is_float = val =>
  typeof val === 'number' && parseInt(val) === val
ExScript.Modules.Kernel.is_function = val => typeof val === 'function'
ExScript.Modules.Kernel.is_integer = val =>
  typeof val === 'number' && !ExScript.is_float(val)
ExScript.Modules.Kernel.is_list = val => val instanceof Array
ExScript.Modules.Kernel.is_map = val => typeof val === 'object'
ExScript.Modules.Kernel.is_nil = val => typeof val === null
ExScript.Modules.Kernel.is_number = val => typeof val === 'number'
ExScript.Modules.Kernel.is_pid = val => typeof val === 'boolean'
ExScript.Modules.Kernel.is_port = val => typeof val === 'boolean'
ExScript.Modules.Kernel.is_reference = val => typeof val === 'boolean'
ExScript.Modules.Kernel.is_tuple = val => val instanceof ExScript.Types.Tuple
ExScript.Modules.Kernel.length = val => val.length
