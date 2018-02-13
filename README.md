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

Before contributing:

```
mix test
mix format mix.exs "lib/**/*.{ex,exs}" "test/**/*.{exs}"
```
