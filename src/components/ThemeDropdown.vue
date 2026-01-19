<script setup lang="ts">
import { ref } from "vue";
import CarbonChevronDown from "~icons/carbon/chevron-down";

const { itemMap, modelValue } = defineProps<{
  itemMap: Record<string, string[]>;
  modelValue: string;
}>();
const emit = defineEmits(["update:modelValue"]);

const selectedName = ref(modelValue);
const listVisible = ref(false);
</script>

<template>
  <div class="relative z-10 w-64 cursor-pointer select-none text-left">
    <div class="flex items-center justify-between border border-neutral-600 bg-neutral-900 px-4 py-1"
      @click="listVisible = !listVisible">
      <p>{{ selectedName }}</p>
      <div class="flex gap-2">
        <div class="flex items-stretch">
          <div v-for="color in modelValue" :style="{ background: color }" class="h-4 w-2"></div>
        </div>
        <CarbonChevronDown class="h-4 w-4" />
      </div>
    </div>
    <div v-show="listVisible"
      class="*:flex *:hover:bg-neutral-800 *:px-4 *:py-1 *:items-center *:justify-between absolute left-0 right-0 top-8 mt-px max-h-80 overflow-y-scroll border border-neutral-600 bg-neutral-900 text-sm">
      <div v-for="(colors, name) in itemMap" @click="
        selectedName = name;
      listVisible = !listVisible;
      emit('update:modelValue', name);
      ">
        <p>{{ name }}</p>
        <div class="flex items-stretch">
          <div v-for="color in colors" :style="{ background: color }" class="h-4 w-2"></div>
        </div>
      </div>
    </div>
  </div>
</template>
