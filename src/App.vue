<script setup lang="ts">
import { ref, useTemplateRef } from "vue";
import Renderer from "./components/Renderer.vue";

const equation1 = ref("x*(pow(x, 2.0) + pow(y, 2.0) - 1.0)");
const equation2 = ref("0.0");

const rendererRef = useTemplateRef("renderer");
</script>

<template>
  <main class="flex flex-col items-center gap-2 p-8 text-center">
    <h1 class="text-4xl">Equation Vis</h1>
    <h2 class="mb-4">Visualize math equations as a heatmap</h2>
    <p>Enter equation</p>
    <p class="text-xs text-neutral-300">
      Equation should be a valid GLSL expression in terms of x and y.
      <br />
      All numbers must be floats.
    </p>
    <div class="flex max-w-full items-center gap-1">
      <div>
        <input
          type="text"
          class="w-full border border-neutral-700 px-2 py-1 outline-0"
          v-model="equation1"
          placeholder="y"
        />
      </div>
      <p>=</p>
      <div>
        <input
          type="text"
          class="w-full border border-neutral-700 px-2 py-1 outline-0"
          v-model="equation2"
          placeholder="pow(x, 2) - 1"
        />
      </div>
    </div>

    <button class="cursor-pointer bg-neutral-800 px-4 py-2" @click="rendererRef?.vis()">
      Visualize!
    </button>

    <Renderer :equation1="equation1" :equation2="equation2" ref="renderer" />
  </main>
</template>
