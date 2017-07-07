const acorn = require('acorn')
const escodegen = require('escodegen')

console.log(escodegen.generate({
    type: 'BinaryExpression',
    operator: '+',
    left: { type: 'Literal', value: 40 },
    right: { type: 'Literal', value: 2 }
}))