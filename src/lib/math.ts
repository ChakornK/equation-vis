// @ts-nocheck

import { create, all, type FactoryFunctionMap, type MathNode } from "mathjs";
const math = create(all as FactoryFunctionMap);

export const exprToGlsl = (e: string) => {
  let expression = math.parse(e);
  expression = math.simplify(expression);
  expression = expression.transform((node) => {
    if (node.op === "^") {
      return new math.FunctionNode("c_pow", [node.args[0], node.args[1]]);
    }
    return node;
  });

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
