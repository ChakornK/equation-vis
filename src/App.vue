<script setup lang="ts">
import { ref, useTemplateRef } from "vue";
import Renderer from "./components/Renderer.vue";

const equation1 = ref("");
const equation2 = ref("");

const rendererRef = useTemplateRef("renderer");
</script>

<template>
  <main class="flex flex-col items-center gap-2 p-8 text-center">
    <h1 class="text-4xl">Equation Vis</h1>
    <h2 class="mb-4">Visualize math equations as a heatmap</h2>
    <p>Enter equation</p>
    <p class="text-xs text-neutral-300">
      Equation should be a valid GLSL expression in terms of x and y
    </p>
    <p>
      <input
        type="text"
        class="border border-neutral-700 px-2 py-1 outline-0"
        v-model="equation1"
        placeholder="y"
      />
      =
      <input
        type="text"
        class="border border-neutral-700 px-2 py-1 outline-0"
        v-model="equation2"
        placeholder="pow(x, 2) - 1"
      />
    </p>

    <button class="cursor-pointer bg-neutral-800 px-4 py-2" @click="rendererRef?.vis()">
      Visualize!
    </button>

    <Renderer :equation1="equation1" :equation2="equation2" ref="renderer" />
  </main>
</template>
