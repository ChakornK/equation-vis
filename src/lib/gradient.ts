import themes from "./gradient.yaml";
export { themes };

export const glslGradient = (theme: string[]) => {
  const n = theme.length - 1;
  let conds = "";
  for (let i = 0; i < n; i++) {
    const hex1 = theme[i];
    const hex2 = theme[i + 1];
    if (!hex1 || !hex2) return "vec4 gradient(float v) { return vec4(0.0, 0.0, 0.0, 1.0); }";
    const r1 = parseInt(hex1.substring(1, 3), 16).toFixed(1);
    const g1 = parseInt(hex1.substring(3, 5), 16).toFixed(1);
    const b1 = parseInt(hex1.substring(5, 7), 16).toFixed(1);
    const r2 = parseInt(hex2.substring(1, 3), 16).toFixed(1);
    const g2 = parseInt(hex2.substring(3, 5), 16).toFixed(1);
    const b2 = parseInt(hex2.substring(5, 7), 16).toFixed(1);
    conds += `
if (v < ${((i + 1) / n).toFixed(2)}) {
  return mix(vec4(${r1}/255.0, ${g1}/255.0, ${b1}/255.0, 1.0), vec4(${r2}/255.0, ${g2}/255.0, ${b2}/255.0, 1.0), (v - ${(i / n).toFixed(2)}) * ${n.toFixed(1)});
}`;
    if (i === n - 1) {
      conds += `
return vec4(${r2}/255.0, ${g2}/255.0, ${b2}/255.0, 1.0);`;
    }
  }
  return `vec4 gradient(float v) { ${conds} }`;
};
