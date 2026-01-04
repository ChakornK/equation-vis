<script setup lang="ts">
import { glslGradient, themes } from "@/lib/gradient";
import { exprToGlsl } from "@/lib/math";
import { onMounted, useTemplateRef } from "vue";

import fragment from "../shader/fragment.glsl";
import vertex from "../shader/vertex.glsl";

const { equation1, equation2 } = defineProps({
  equation1: { type: String, required: true },
  equation2: { type: String, required: true },
});

const vs = vertex;

const sh = (gl: WebGLRenderingContext, t: GLenum, s: string) => {
  const x = gl.createShader(t) as WebGLShader;
  gl.shaderSource(x, s);
  gl.compileShader(x);
  return x as WebGLShader;
};

const canvasRef = useTemplateRef<HTMLCanvasElement>("canvas");
const vis = () => {
  const canvas = canvasRef.value;
  if (!canvas) return;
  const gl = canvas.getContext("webgl");
  if (!gl) return alert("WebGL not supported");

  let fs = fragment;

  const replaceMap = {
    CONST_SCALE: `float scale = 20.0;`,
    CONST_FALLOFF: `float falloff = 3.5;`,
    CONST_WIDTH: `float width = 512.0;`,
    CONST_HEIGHT: `float height = 512.0;`,
    FN_EQ1: `
float equation1(float x, float y) {
  return ${exprToGlsl(equation1)};
}`,
    FN_EQ2: `
float equation2(float x, float y) {
  return ${exprToGlsl(equation2)};
}`,
    FN_GRADIENT: glslGradient(themes.argon),
  };
  for (const k in replaceMap) {
    fs = fs.replace(`#${k};`, replaceMap[k as keyof typeof replaceMap]);
  }

  gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
  gl.clearColor(0, 0, 0, 1);
  gl.clear(gl.COLOR_BUFFER_BIT);

  const program = gl.createProgram();
  gl.attachShader(program, sh(gl, gl.VERTEX_SHADER, vs));
  gl.attachShader(program, sh(gl, gl.FRAGMENT_SHADER, fs));
  gl.linkProgram(program);
  gl.useProgram(program);

  const buf = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, buf);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);

  const loc = gl.getAttribLocation(program, "p");
  gl.enableVertexAttribArray(loc);
  gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

  gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

  const err = gl.getProgramInfoLog(program);
  if (err) alert(err);
};
onMounted(vis);

defineExpose({ vis });
</script>

<template>
  <canvas class="max-w-full" width="512" height="512" ref="canvas"></canvas>
</template>
