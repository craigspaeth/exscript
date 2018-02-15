//
// A JS library used to implement Elixir/Erlang standard library or language
// features that don't translate very cleanly 1:1.
//
const ExScript = { Modules: { ExScript: { Stdlib: {} } } }
const root = typeof window === 'undefined' ? global : window

// Namespace for user-land modules
ExScript.Modules = {}
ExScript.Modules.JS = {
  window: () => root
}
ExScript.Modules.IO = {
  puts: root.console.log,
  inspect: root.console.debug
}

// Data Types
ExScript.Types = {}
ExScript.Types.Tuple = class Tuple extends Array {}

// Standard library

// Atom
ExScript.Modules.Atom = {}
ExScript.Modules.Atom.to_string = atom => String(atom).slice(7, -1)

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
ExScript.Modules.ExScriptStdlibEnum = {
    map(e, fun) {
        return e.map(i => {
            return fun(i);
        });
    },
    reduce(enumerable, arg2, arg3) {
        const reducer = arg3 || arg2;
        const initVal = arg3 ? arg2 : enumerable[0];
        const callback = (acc, val, i) => reducer(val, acc);
        return Array.prototype.reduce.call(enumerable, callback, initVal);;
    },
    join(e, char) {
        return Array.prototype.join.call(e, char);;
    },
    at(e, index) {
        return e[index];;
    }
};for (let key in ExScript.Modules) {
  if (key.match(/^ExScriptStdlib/)) {
    const modName = key.replace('ExScriptStdlib', '')
    ExScript.Modules[modName] = ExScript.Modules[key]
  }
}
ExScript.Modules.App = {
    init() {
        return this.render_name('Harry');
    },
    render_name(name) {
        return ViewClient.render(View, { name: name });
    }
};
ExScript.Modules.ViewClient = {
    to_react_el(dsl_el) {
        let tag_label, children, attrs, _, childs;
        [tag_label, ...children] = dsl_el;
        attrs = Keyword['keyword?'](List.first(children)) ? (() => {
            return Enum.reduce(List.first(children), {}, ([k, v], acc) => {
                return Map.put(acc, Atom.to_string(k), v);
            });
        })() : null;
        [_, ...childs] = attrs !== null ? (() => {
            return children;
        })() : (() => {
            return [null].concat(children);
        })();
        return (() => {
            if (Kernel.is_bitstring(List.first(childs))) {
                return this.text_node(tag_label, attrs, List.first(childs));
            } else if (true) {
                return Enum.map(childs, el => {
                    return this.to_react_el(el);
                });
            }
        })();
    },
    text_node(tag_label, attrs, text) {
        return JS.window()['React'].createElement(props => {
            return JS.window()['React'].createElement(Atom.to_string(tag_label), attrs, text);
        }, {});
    },
    render(view, model) {
        let el;
        el = this.to_react_el(view.render(model));
        return JS.window()['ReactDOM'].render(el, JS.window()['document']['body']);
    }
};
ExScript.Modules.View = {
    onclick(e) {
        return IO.inspect(e);
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
const {ViewClient, View, Keyword, List, Enum, Map, Atom, Kernel, JS, IO} = ExScript.Modules;