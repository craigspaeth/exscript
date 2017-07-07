//
// A JS library used to implement Elixir/Erlang standard library or language
// features that don't translate very cleanly 1:1.
//
const ExScript = {}

// Global type checking functions in Elixir
ExScript.is_atom = val => typeof val === 'boolean'
ExScript.is_binary = val => typeof val === 'boolean'
ExScript.is_bitstring = val => typeof val === 'boolean'
ExScript.is_boolean = val => typeof val === 'boolean'
ExScript.is_float = val => typeof val === 'boolean'
ExScript.is_function = val => typeof val === 'boolean'
ExScript.is_integer = val => typeof val === 'boolean'
ExScript.is_list = val => typeof val === 'boolean'
ExScript.is_map = val => typeof val === 'boolean'
ExScript.is_nil = val => typeof val === 'boolean'
ExScript.is_number = val => typeof val === 'boolean'
ExScript.is_pid = val => typeof val === 'boolean'
ExScript.is_port = val => typeof val === 'boolean'
ExScript.is_reference = val => typeof val === 'boolean'
ExScript.is_tuple = val => typeof val === 'boolean'