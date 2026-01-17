<script setup lang="ts">
import { glslGradient } from "@/lib/gradient";
import { exprToGlsl } from "@/lib/math";
import { onMounted, onUnmounted, ref, useTemplateRef } from "vue";
import CarbonWarningAlt from "~icons/carbon/warning-alt";

import fragment from "../shader/fragment.glsl";
import vertex from "../shader/vertex.glsl";

const viewportScale = ref(20);
const viewportX = ref(0);
const viewportY = ref(0);
const falloff = ref(3.5);

const rerender = () => {
  vis({ useCache: true });
};

const viewportInitScale = ref<number | null>(null);
const viewportInitXY = ref<{ x: number; y: number } | null>(null);
const pointerDown = ref(false);
const pointerStart = ref<{ id: number; x: number; y: number }[] | null>(null);
const pointerPos = ref<{ id: number; x: number; y: number }[] | null>(null);
const onPointerDown = (e: PointerEvent) => {
  if (pointerStart.value === null) {
    pointerStart.value = [];
    pointerPos.value = [];
    viewportInitScale.value = viewportScale.value;
    viewportInitXY.value = { x: viewportX.value, y: viewportY.value };
  }
  pointerStart.value?.push({ id: e.pointerId, x: e.clientX, y: e.clientY });
  pointerDown.value = true;
  document.addEventListener("pointerup", onPointerUp, { once: true });
};
const onPointerUp = (e: PointerEvent) => {
  if (!pointerStart.value || !pointerPos.value) return;
  pointerStart.value = pointerStart.value.filter((p) => p.id !== e.pointerId);
  pointerPos.value = pointerPos.value?.filter((p) => p.id !== e.pointerId);
  if (pointerStart.value.length === 0) {
    pointerDown.value = false;
    pointerStart.value = null;
    pointerPos.value = null;
  }
};
const onPointerMove = (e: PointerEvent) => {
  if (!pointerDown.value || !pointerStart.value) return;
  pointerPos.value = pointerStart.value.map((p) => {
    if (p.id === e.pointerId) {
      return { id: p.id, x: e.clientX, y: e.clientY };
    }
    return p;
  });

  if (pointerPos.value.length === 2) {
    const p1Start = pointerStart.value.find((p) => p.id === pointerPos.value![0]!.id);
    const p2Start = pointerStart.value.find((p) => p.id === pointerPos.value![1]!.id);
    if (p1Start && p2Start) {
      const distStart = Math.hypot(p2Start.x - p1Start.x, p2Start.y - p1Start.y);
      const distNow = Math.hypot(
        pointerPos.value![1]!.x - pointerPos.value![0]!.x,
        pointerPos.value![1]!.y - pointerPos.value![0]!.y,
      );
      const scaleChange = distNow / distStart;
      if (viewportInitScale.value !== null) {
        viewportScale.value = viewportInitScale.value / scaleChange;
      }
    }
  }

  const d = pointerPos.value
    .map((p) => {
      const start = pointerStart.value?.find((s) => s.id === p.id);
      if (!start) return { x: 0, y: 0 };
      return { x: p.x - start.x, y: p.y - start.y };
    })
    .reduce(
      (acc, cur) => {
        return {
          x: acc.x + cur.x / pointerPos.value!.length,
          y: acc.y + cur.y / pointerPos.value!.length,
        };
      },
      { x: 0, y: 0 },
    );
  if (viewportInitXY.value) {
    viewportX.value = viewportInitXY.value.x - (d.x * viewportScale.value) / width;
    viewportY.value = viewportInitXY.value.y + (d.y * viewportScale.value) / height;
  }

  rerender();
};
const onScroll = (e: WheelEvent) => {
  const delta = e.deltaY;
  const scaleFactor = 1.05;
  if (delta < 0) {
    viewportScale.value /= scaleFactor;
  } else {
    viewportScale.value *= scaleFactor;
  }
  rerender();
};
const eventPreventDefault = (e: Event) => {
  e.preventDefault();
};
onMounted(() => {
  window.addEventListener("pointermove", onPointerMove);
});
onUnmounted(() => {
  window.removeEventListener("pointermove", onPointerMove);
});

const width = 512;
const height = 512;

const errorMsg = ref("");

const vs = vertex;
const canvasRef = useTemplateRef<HTMLCanvasElement>("canvas");

let gl: WebGL2RenderingContext | null = null;
let program: WebGLProgram | null = null;
let buf: WebGLBuffer | null = null;

let uScale: WebGLUniformLocation | null = null;
let uX: WebGLUniformLocation | null = null;
let uY: WebGLUniformLocation | null = null;
let uW: WebGLUniformLocation | null = null;
let uH: WebGLUniformLocation | null = null;
let uFalloff: WebGLUniformLocation | null = null;

const sh = (t: GLenum, s: string) => {
  const x = gl!.createShader(t)!;
  gl!.shaderSource(x, s);
  gl!.compileShader(x);
  return x;
};

const equationCache = ref({ equation1: "", equation2: "" });
const themeCache = ref<string[]>([]);

const vis = ({ equation1, equation2, theme, useCache }: any) => {
  try {
    const canvas = canvasRef.value;
    if (!canvas) return;

    if (!gl) {
      gl = canvas.getContext("webgl2");
      if (!gl) throw new Error("no webgl");

      buf = gl.createBuffer();
      gl.bindBuffer(gl.ARRAY_BUFFER, buf);
      gl.bufferData(
        gl.ARRAY_BUFFER,
        new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]),
        gl.STATIC_DRAW,
      );
    }

    const eq1 = useCache ? equationCache.value.equation1 : exprToGlsl(equation1);
    const eq2 = useCache ? equationCache.value.equation2 : exprToGlsl(equation2);
    const t = useCache ? themeCache.value : theme;

    if (!useCache || !program) {
      equationCache.value = { equation1: eq1, equation2: eq2 };
      themeCache.value = t;

      let fs = fragment;
      const replaceMap = {
        FN_EQ1: `float equation1(float x, float y){ return ${eq1}; }`,
        FN_EQ2: `float equation2(float x, float y){ return ${eq2}; }`,
        FN_GRADIENT: glslGradient(t),
      };

      for (const k in replaceMap) {
        fs = fs.replace(`#${k};`, replaceMap[k as keyof typeof replaceMap]);
      }

      if (program) gl.deleteProgram(program);

      program = gl.createProgram()!;
      gl.attachShader(program, sh(gl.VERTEX_SHADER, vs));
      gl.attachShader(program, sh(gl.FRAGMENT_SHADER, fs));
      gl.linkProgram(program);

      uScale = gl.getUniformLocation(program, "viewportScale");
      uX = gl.getUniformLocation(program, "viewportX");
      uY = gl.getUniformLocation(program, "viewportY");
      uW = gl.getUniformLocation(program, "width");
      uH = gl.getUniformLocation(program, "height");
      uFalloff = gl.getUniformLocation(program, "falloff");
    }

    gl.useProgram(program);
    gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);
    gl.clearColor(0, 0, 0, 1);
    gl.clear(gl.COLOR_BUFFER_BIT);

    gl.uniform1f(uScale!, viewportScale.value);
    gl.uniform1f(uX!, viewportX.value);
    gl.uniform1f(uY!, viewportY.value);
    gl.uniform1f(uW!, width);
    gl.uniform1f(uH!, height);
    gl.uniform1f(uFalloff!, falloff.value);

    gl.bindBuffer(gl.ARRAY_BUFFER, buf);
    const loc = gl.getAttribLocation(program, "p");
    gl.enableVertexAttribArray(loc);
    gl.vertexAttribPointer(loc, 2, gl.FLOAT, false, 0, 0);

    gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

    errorMsg.value = gl.getProgramInfoLog(program) || "";

  } catch (e) {
    errorMsg.value = (e as Error).message;
  }
};


defineExpose({ vis });
</script>

<template>
  <div :style="{
    width: `${width}px`,
    height: `${height}px`,
  }" class="relative max-w-full">
    <canvas class="absolute inset-0 max-w-full" :width="width" :height="height" ref="canvas"
      @pointerdown="onPointerDown" @wheel="onScroll" @gesturestart="eventPreventDefault"
      @touchstart="eventPreventDefault"></canvas>
    <div v-if="errorMsg"
      class="peer absolute left-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-red-500">
      <CarbonWarningAlt class="-mt-1 h-4 w-4" />
    </div>
    <div
      class="absolute left-2 top-11 hidden max-w-full border border-neutral-600 bg-neutral-800 p-4 text-left font-mono peer-hover:block">
      <p>Error</p>
      <p class="text-sm text-neutral-300">
        <span class="block" v-for="l in errorMsg.split('\n')">{{ l }}</span>
      </p>
    </div>
  </div>
</template>
