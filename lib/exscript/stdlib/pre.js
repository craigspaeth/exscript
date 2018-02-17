//
// A JS library used to implement Elixir/Erlang standard library or language
// features that don't translate very cleanly 1:1.
//
const ExScript = { Modules: { ExScript: { Stdlib: {} } } }

// Data Types
class Tup extends Array {}

// Standard library (TODO: Replace with ExScript wrappers)

// Map
ExScript.Modules.Map = {}
ExScript.Modules.Map.put = (map, key, val) => {
  map[key] = val
  return map
}

// List
ExScript.Modules.List = {}
ExScript.Modules.List.first = list => list[0]

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
