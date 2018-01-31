# exscript

Takes an Elixir AST, converts it to an ESTree JSON AST, and uses Escodegen to generate Javascript code from that.
 
## Getting Started

```
brew install node
npm install
brew install elixir
mix deps.get
mix test
mix example
open example/index.html
```

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

### Bugs

- [x] Moduledocs unsupported
- [ ] External module references

### Interop story

Research more about FFIs :thinking_face:

- [x] Debugger
- [ ] JS module loading
- [ ] Classes /shrug
- [ ] Mutation /shrug

### Refactoring

- Break up into module around Elixir primatives or chapter heads in the guide (Basic types, Basic operators, etc.)
- Hoist ExScript namespace to top of module
- Figure out standard lib story (compile from Elixir src, testing, etc?)
- let instead of const
- Ensure all variables are being copied
- Anonymous functions on single line use ES6 shorthand
- Ternery with one expression doesn't need closure

### Tooling

- Watch task
- Development/Production builds
- Source maps

### Self hosting

- Somehow remove the dependency on Node (acor, escodegen, and node -e)