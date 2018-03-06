(() => {
  class Tup extends Array {};
const ExScriptStdlibTuple = {};
const ExScriptStdlibString = {
    split(_string, _pattern) {
        return _string.split(_pattern);;
    },
    to_atom(_str) {
        return Symbol(_str);;
    },
    replace(_subject, _pattern, _replacement) {
        return _subject.replace(_pattern, _replacement);;
    },
    capitalize(_str) {
        return _str.charAt(0).toUpperCase() + _str.slice(1);;
    }
};
const ExScriptStdlibMap = {
    merge(map1, map2) {
        return Object.assign({}, map1, map2);;
    },
    put(map, key, val) {
        let k;
        k = Atom.to_string(key);
        return Object.assign({}, map, { [k]: val });;
    }
};
const ExScriptStdlibList = {
    first(_list) {
        return _list[0];;
    }
};
const ExScriptStdlibKeyword = {
    merge(keywords1, keywords2) {
        let both;
        both = keywords1.concat(keywords2);
        return both.map(([k, _]) => {
            return new Tup(k, Keyword.get(both, k));
        });
    },
    "has_key?"(keywords, key) {
        let bools;
        bools = keywords.map(([k, _]) => {
            return Atom.to_string(k) === Atom.to_string(key);
        });
        return Enum['member?'](bools, true);
    },
    get(keywords, key) {
        return Enum.reduce(Enum.reverse(keywords), ([k, v], acc) => {
            return Atom.to_string(k) === Atom.to_string(key) ? (() => {
                return v;
            })() : (() => {
                return acc;
            })();
        });
    },
    "keyword?"(keywords) {
        return keywords && Kernel.length(keywords) > 0 ? (() => {
            let first, _;
            [first, ..._] = keywords;
            return Kernel.is_tuple(first) ? (() => {
                let k, v;
                [k, v] = first;
                return Kernel.is_atom(k);
            })() : false;
        })() : false;
    }
};
const ExScriptStdlibKernel = {
    length(val) {
        return val.length;;
    },
    is_tuple(val) {
        return val instanceof Tup;;
    },
    is_atom(val) {
        return typeof val === 'symbol';;
    },
    is_bitstring(val) {
        return typeof val === 'string';;
    },
    is_list(val) {
        return val instanceof Array;;
    },
    is_map(val) {
        return typeof val === 'object';;
    }
};
const ExScriptStdlibJS = {
    root() {
        return typeof global !== 'undefined' && global || typeof window !== 'undefined' && window || {};;
    }
};
const ExScriptStdlibIO = {
    puts(str) {
        return console.log(str);;
    },
    inspect(str) {
        return console.debug(str);;
    }
};
const ExScriptStdlibExScriptAwait = {};
const ExScriptStdlibEnum = {
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
    },
    "member?"(enumerable, element) {
        return this.reduce(enumerable, false, (i, acc) => {
            return acc || i === element;
        });
    },
    with_index(enumerable) {
        let __i = 0;
        return enumerable.map(i => {
            let index;
            __i++;
            index = __i - 1;;
            return new Tup(i, index);
        });
    },
    reverse(enumerable) {
        return enumerable.slice().reverse();;
    }
};
const ExScriptStdlibAtom = {
    to_string(atom) {
        return JS.root().String(atom).slice(7, -1);;
    }
};
(window.ExScript = {
    ...window.ExScript,
    ExScriptStdlibTuple,
    ExScriptStdlibString,
    ExScriptStdlibMap,
    ExScriptStdlibList,
    ExScriptStdlibKeyword,
    ExScriptStdlibKernel,
    ExScriptStdlibJS,
    ExScriptStdlibIO,
    ExScriptStdlibExScriptAwait,
    ExScriptStdlibEnum,
    ExScriptStdlibAtom
})
const Atom = ExScriptStdlibAtom;
const Enum = ExScriptStdlibEnum;
const ExScriptAwait = ExScriptStdlibExScriptAwait;
const IO = ExScriptStdlibIO;
const JS = ExScriptStdlibJS;
const Kernel = ExScriptStdlibKernel;
const Keyword = ExScriptStdlibKeyword;
const List = ExScriptStdlibList;
const Map = ExScriptStdlibMap;
const String = ExScriptStdlibString;
const Tuple = ExScriptStdlibTuple;

  const ViewClient = {
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
const View = {
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
                    [new Tup(Symbol('href'), 'hi')],
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
                    [new Tup(Symbol('onClick'), this.onclick)],
                    'Hello World'
                ]
            ]
        ];
    }
};
const App = {
    init() {
        return this.render_name('Harry');
    },
    render_name(name) {
        return ViewClient.render(View, { name: name });
    }
};
(window.ExScript = {
    ...window.ExScript,
    ViewClient,
    View,
    App
});
})()
