<script setup lang="ts">
import { glslGradient } from "@/lib/gradient";
import { exprToGlsl, toFloat } from "@/lib/math";
import { onMounted, onUnmounted, ref, useTemplateRef } from "vue";
import CarbonWarningAlt from "~icons/carbon/warning-alt";

import fragment from "../shader/fragment.glsl";
import vertex from "../shader/vertex.glsl";
import { throttle } from "@/lib/throttle";

const viewportScale = ref(20);
const viewportX = ref(0);
const viewportY = ref(0);

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
  window.addEventListener("pointermove", throttle(onPointerMove, 8));
});
onUnmounted(() => {
  window.removeEventListener("pointermove", throttle(onPointerMove, 8));
});

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

const equationCache = ref<{ equation1: string; equation2: string }>({
  equation1: "",
  equation2: "",
});
const themeCache = ref<string[]>([]);
const canvasRef = useTemplateRef<HTMLCanvasElement>("canvas");
const vis = ({
  equation1,
  equation2,
  theme,
  useCache,
}: {
  equation1?: string;
  equation2?: string;
  theme?: string[];
  useCache?: boolean;
}) => {
  try {
    const canvas = canvasRef.value;
    if (!canvas) return;
    const gl = canvas.getContext("webgl2");
    if (!gl) throw new Error("WebGL not supported");

    let fs = fragment;

    const eq1 = useCache || !equation1 ? equationCache.value.equation1 : exprToGlsl(equation1);
    const eq2 = useCache || !equation2 ? equationCache.value.equation2 : exprToGlsl(equation2);
    const t = useCache || !theme ? themeCache.value : theme;
    if (!useCache) {
      equationCache.value = { equation1: eq1, equation2: eq2 };
      themeCache.value = theme as string[];
    }
    const replaceMap = {
      CONST_VIEWPORT_SCALE: `float viewportScale = ${toFloat(viewportScale.value)};`,
      CONST_VIEWPORT_X: `float viewportX = ${toFloat(viewportX.value)};`,
      CONST_VIEWPORT_Y: `float viewportY = ${toFloat(viewportY.value)};`,
      CONST_FALLOFF: `float falloff = 3.5;`,
      CONST_WIDTH: `float width = ${toFloat(width)};`,
      CONST_HEIGHT: `float height = ${toFloat(height)};`,
      FN_EQ1: `
float equation1(float x, float y) {
  return ${eq1};
}`,
      FN_EQ2: `
float equation2(float x, float y) {
  return ${eq2};
}`,
      FN_GRADIENT: glslGradient(t),
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
  <div :style="{
    width: `${width}px`,
    height: `${height}px`,
  }" class="relative max-w-full">
    <canvas class="absolute inset-0 max-w-full" :width="width" :height="height" ref="canvas"
      @pointerdown="onPointerDown" @pointerup="onPointerUp" @wheel="onScroll" @gesturestart="eventPreventDefault"
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
