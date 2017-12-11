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
ExScript.Modules.App = {
    init() {
        return this.render_name('Harry');
    },
    render_name(name) {
        return ExScript.Modules.ViewClient.render(ExScript.Modules.View, { name: name });
    }
};
ExScript.Modules.ViewClient = {
    to_react_el(dsl_el) {
        const [tag_label, ...children] = dsl_el;
        const attrs = ExScript.Modules.Keyword['keyword?'](ExScript.Modules.List.first(children)) ? (() => {
            return ExScript.Modules.Enum.reduce(ExScript.Modules.List.first(children), {}, ([k, v], acc) => {
                return ExScript.Modules.Map.put(acc, ExScript.Modules.Atom.to_string(k), v);
            });
        })() : null;
        const [_, ...childs] = attrs !== null ? (() => {
            return children;
        })() : (() => {
            return [null].concat(children);
        })();
        return (() => {
            if (ExScript.Modules.Kernel.is_bitstring(ExScript.Modules.List.first(childs))) {
                return this.text_node(tag_label, attrs, ExScript.Modules.List.first(childs));
            } else if (true) {
                return ExScript.Modules.Enum.map(childs, el => {
                    return this.to_react_el(el);
                });
            }
        })();
    },
    text_node(tag_label, attrs, text) {
        return ExScript.Modules.JS.window()['React'].createElement(props => {
            return ExScript.Modules.JS.window()['React'].createElement(ExScript.Modules.Atom.to_string(tag_label), attrs, text);
        }, {});
    },
    render(view, model) {
        const el = this.to_react_el(view.render(model));
        return ExScript.Modules.JS.window()['ReactDOM'].render(el, ExScript.Modules.JS.window()['document']['body']);
    }
};
ExScript.Modules.View = {
    onclick(e) {
        return ExScript.Modules.IO.inspect(e);
    },
    render(model) {
        return [
            Symbol('div'),
            [
                Symbol('h2'),
                'Welcome'
            ],
            [
                Symbol('h1'),
                `Hello ${ model.name }`
            ],
            [
                Symbol('ul'),
                [
                    Symbol('li'),
                    'a'
                ],
                [
                    Symbol('li'),
                    'b'
                ],
                [
                    Symbol('a'),
                    [new ExScript.Types.Tuple(Symbol('href'), 'hi')],
                    [
                        Symbol('p'),
                        'a'
                    ],
                    [
                        Symbol('p'),
                        'Hello World'
                    ]
                ],
                [
                    Symbol('button'),
                    [new ExScript.Types.Tuple(Symbol('onClick'), this.onclick)],
                    'Hello World'
                ]
            ]
        ];
    }
};