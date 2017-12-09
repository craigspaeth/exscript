# exscript

Takes an Elixir AST, converts it to an ESTree JSON AST, and uses Escodegen to generate Javascript code from that. Check out the `mix run` task to test it out.

## Mapping Types

- [x] Integer/Float: Number
- [x] Boolean: Boolean
- [x] Atom: Symbol
- [x] String/Binary: String
- [x] Function: Function
- [x] List: Array
- [x] Map/Struct: Object
- [x] Nil: Null

- [x] Tuples
- [x] Module: Object
- [ ] PID: Object `new PID("0.34.23")`
- [ ] BitString
- [ ] Charlist
- [ ] Port
- [ ] Reference

## TODO

### Interop story

- [x] Debugger
- JS module loading
- Classes /shrug
- Mutation /shrug

### Refactoring

- Break up into module around Elixir primatives or chapter heads in the guide (Basic types, Basic operators, etc.)
- Hoist ExScript namespace to top of module

### Tooling

- Watch task
- Development/Productiion builds
- Source maps

### Self hosting

- Somehow remove the dependency on Node (acor, escodegen, and node -e)