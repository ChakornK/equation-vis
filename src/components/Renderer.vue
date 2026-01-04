<script setup lang="ts">
import { glslGradient, themes } from "@/lib/gradient";
import { exprToGlsl } from "@/lib/math";
import { onMounted, useTemplateRef } from "vue";

const { equation1, equation2 } = defineProps({
  equation1: { type: String, required: true },
  equation2: { type: String, required: true },
});

const vs = `
attribute vec2 p;
void main() {
  gl_Position = vec4(p, 0, 1);
}
`;

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

  const fs = `
precision mediump float;

float PI = 3.1415926535897932384626433832795;
float E = 2.7182818284590452353602874713527;

float c_pow(float a, float b) {
  return pow(abs(a), b);
}
float c_gamma_pos(float z) {
  const float g = 7.0;
  const float p0 = 0.99999999999980993;
  const float p1 = 676.5203681218851;
  const float p2 = -1259.1392167224028;
  const float p3 = 771.32342877765313;
  const float p4 = -176.61502916214059;
  const float p5 = 12.507343278686905;
  const float p6 = -0.13857109526572012;
  const float p7 = 9.9843695780195716e-6;
  const float p8 = 1.5056327351493116e-7;

  z -= 1.0;
  float x = p0;
  x += p1 / (z + 1.0);
  x += p2 / (z + 2.0);
  x += p3 / (z + 3.0);
  x += p4 / (z + 4.0);
  x += p5 / (z + 5.0);
  x += p6 / (z + 6.0);
  x += p7 / (z + 7.0);
  x += p8 / (z + 8.0);

  float t = z + g + 0.5;
  return sqrt(2.0 * PI) * pow(t, z + 0.5) * exp(-t) * x;
}

float c_gamma(float z) {
  if (z < 0.5) {
      // reflection formula
      return PI /
          (sin(PI * z) * c_gamma_pos(1.0 - z));
  }
  return c_gamma_pos(z);
}


float scale = 20.0;
float falloff = 3.5;

float rFalloff = 1.0 / falloff;

float equation1(float x, float y) {
  return ${exprToGlsl(equation1)};
}
float equation2(float x, float y) {
  return ${exprToGlsl(equation2)};
}
${glslGradient(themes.argon)}

float a(float x, float y) {
  return rFalloff*abs(equation1((x-256.0)/512.0*scale, (y-256.0)/512.0*scale) - equation2((x-256.0)/512.0*scale, (y-256.0)/512.0*scale) );
}
void main() {
  float n = a(gl_FragCoord.x, gl_FragCoord.y);
  gl_FragColor = gradient(n);
}
`;

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
