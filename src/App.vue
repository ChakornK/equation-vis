<script setup lang="ts">
import { ref, useTemplateRef, watch, watchEffect } from "vue";
import Renderer from "./components/Renderer.vue";
import { themes } from "./lib/gradient";
import ThemeDropdown from "./components/ThemeDropdown.vue";

const equation1 = ref("min(abs(y * (x^0.2 + y^0.2 - 4) * 67sin(x * y)), abs(y * (x^2 + y^2 - 4)))");
const equation2 = ref("0");

const theme = ref(themes["Argon"]);

const rendererRef = useTemplateRef("renderer");
watch([equation1, equation2, theme, rendererRef], () => {
  rendererRef.value?.vis({ equation1: equation1.value, equation2: equation2.value, theme: theme.value });
});
</script>

<template>
  <main class="flex flex-col items-center gap-2 px-2 py-8 text-center">
    <h1 class="text-4xl">Equation Vis</h1>
    <h2 class="mb-4">Visualize math equations as a heatmap</h2>
    <p>Enter equation</p>
    <p class="text-xs text-neutral-300">Equation should be in terms of x and y.</p>
    <div class="flex max-w-full items-center gap-1">
      <div>
        <input type="text" class="w-full border border-neutral-700 px-2 py-1 outline-0" v-model="equation1"
          placeholder="LHS" />
      </div>
      <p>=</p>
      <div>
        <input type="text" class="w-full border border-neutral-700 px-2 py-1 outline-0" v-model="equation2"
          placeholder="RHS" />
      </div>
    </div>
    <div>
      <p>
        Theme
        <span class="text-[0.625rem] text-neutral-400">
          (<a href="https://github.com/axismaps/colorbrewer/blob/master/colorbrewer_schemes.js">source 1</a>, <a
            href="https://github.com/ghosh/uiGradients/blob/master/gradients.json">source 2</a>)
        </span>
      </p>
      <ThemeDropdown :itemMap="themes" v-model="theme" />
    </div>

    <Renderer ref="renderer" />
  </main>
</template>
