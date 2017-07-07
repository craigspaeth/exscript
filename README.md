# exscript

Takes an Elixir AST, converts it to an ESTree JSON AST, and uses Escodegen to generate Javascript code from that. Check out the `mix play` task to test it out.

## Mapping Types

- [x] Integer/Float: Number
- [x] Boolean: Boolean
- [x] Atom: Symbol
- [x] String/Binary: String
- [x] Function: Function
- [x] List: Array
- [x] Map/Struct: Object
- [x] Nil: Null

- [ ] Tuples: Object `{ 0: "A", 1: "2", __type__: "tuple" }`
- [ ] Module: Object `{ __private_func__(){}, public_func(){}, __type__: "module" }`
- [ ] PID: Object `{ id: "0.34.23", __type__: "pid" }`

- [ ] BitString
- [ ] Charlist
- [ ] Port
- [ ] Reference
