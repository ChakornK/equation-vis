// @ts-nocheck

import { create, all, type FactoryFunctionMap, type MathNode } from "mathjs";
const math = create(all as FactoryFunctionMap);

export const exprToGlsl = (e: string) => {
  let expression = math.parse(e);
  expression = math.simplify(expression);
  const transformer = (node) => {
    if (node.op === "^") {
      return new math.FunctionNode("c_pow", [
        node.args[0].transform(transformer),
        node.args[1].transform(transformer),
      ]);
    }
    return node;
  };
  expression = expression.transform(transformer);

  const ret = expression.toString({
    handler: (node: MathNode) => {
      if (node.type === "ConstantNode" && node.value % 1 === 0) {
        return node.value.toFixed(1);
      }
    },
    implicit: "show",
  });
  console.log(ret);
  return ret;
};
