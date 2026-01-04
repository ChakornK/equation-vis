import { fileURLToPath, URL } from "node:url";

import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";
import tailwindcss from "@tailwindcss/vite";
import glsl from "vite-plugin-glsl";
import icons from "unplugin-icons/vite";
import iconComponents from "unplugin-vue-components/vite";

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    icons({ compiler: "vue3" }),
    iconComponents({ dts: true }),
    tailwindcss(),
    glsl(),
  ],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
});
