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
ExScript.Modules.Enum.join = (e, char) => Array.prototype.join.call(e, char)

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
ExScript.Modules.Kernel.is_tuple = val => typeof val === 'boolean'
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
        return (() => {
            if (ExScript.Modules.Kernel.length(children) === 1 && ExScript.Modules.Kernel.is_bitstring(ExScript.Modules.List.first(children))) {
                return this.text_node(dsl_el);
            } else if (ExScript.Modules.Kernel.is_list(ExScript.Modules.List.first(children))) {
                return ExScript.Modules.Enum.map(children, el => {
                    return this.to_react_el(el);
                });
            }
        })();
    },
    text_node(dsl_el) {
        const [tag_label, text] = dsl_el;
        return ExScript.Modules.JS.window()['React'].createElement(props => {
            return ExScript.Modules.JS.window()['React'].createElement(ExScript.Modules.Atom.to_string(tag_label), null, text);
        }, {});
    },
    render(view, model) {
        const el = this.to_react_el(view.render(model));
        return ExScript.Modules.JS.window()['ReactDOM'].render(el, ExScript.Modules.JS.window()['document']['body']);
    }
};
ExScript.Modules.View = {
    render(model) {
        return [
            Symbol('div'),
            [
                Symbol('h2'),
                'Welcome'
            ],
            [
                Symbol('h1'),
                `Hello `
            ]
        ];
    }
};