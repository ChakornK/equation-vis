<script setup lang="ts">
import { glslGradient, themes } from "@/lib/gradient";
import { exprToGlsl } from "@/lib/math";
import { ref, useTemplateRef } from "vue";
import CarbonWarningAlt from "~icons/carbon/warning-alt";

import fragment from "../shader/fragment.glsl";
import vertex from "../shader/vertex.glsl";

const { theme } = defineProps<{ theme: string[] }>();

const width = 512;
const height = 512;

const errorMsg = ref("");

const vs = vertex;

const sh = (gl: WebGLRenderingContext, t: GLenum, s: string) => {
  const x = gl.createShader(t) as WebGLShader;
  gl.shaderSource(x, s);
  gl.compileShader(x);
  return x as WebGLShader;
};

const canvasRef = useTemplateRef<HTMLCanvasElement>("canvas");
const vis = ({ equation1, equation2 }: { equation1: string; equation2: string }) => {
  try {
    const canvas = canvasRef.value;
    if (!canvas) return;
    const gl = canvas.getContext("webgl");
    if (!gl) throw new Error("WebGL not supported");

    let fs = fragment;

    const replaceMap = {
      CONST_SCALE: `float scale = 20.0;`,
      CONST_FALLOFF: `float falloff = 3.5;`,
      CONST_WIDTH: `float width = ${width.toFixed(1)};`,
      CONST_HEIGHT: `float height = ${height.toFixed(1)};`,
      FN_EQ1: `
float equation1(float x, float y) {
  return ${exprToGlsl(equation1)};
}`,
      FN_EQ2: `
float equation2(float x, float y) {
  return ${exprToGlsl(equation2)};
}`,
      FN_GRADIENT: glslGradient(theme),
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
    if (err) {
      errorMsg.value = err;
    } else {
      errorMsg.value = "";
    }
  } catch (e) {
    errorMsg.value = (e as Error).message;
  }
};

defineExpose({ vis });
</script>

<template>
  <div
    :style="{
      width: `${width}px`,
      height: `${height}px`,
    }"
    class="relative max-w-full"
  >
    <canvas
      class="absolute inset-0 max-w-full"
      :width="width"
      :height="height"
      ref="canvas"
    ></canvas>
    <div
      v-if="errorMsg"
      class="peer absolute left-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-red-500"
    >
      <CarbonWarningAlt class="-mt-1 h-4 w-4" />
    </div>
    <div
      class="absolute left-2 top-11 hidden max-w-full border border-neutral-600 bg-neutral-800 p-4 text-left font-mono peer-hover:block"
    >
      <p>Error</p>
      <p class="text-sm text-neutral-300">
        <span class="block" v-for="l in errorMsg.split('\n')">{{ l }}</span>
      </p>
    </div>
  </div>
</template>
