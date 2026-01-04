precision mediump float;

#include constants.glsl;

#include functions/gamma.glsl;
#include functions/pow.glsl;

float scale = 20.0;
float falloff = 3.5;

float rFalloff = 1.0 / falloff;

EQDEFS;

float calc(float x, float y) {
  return rFalloff * abs(equation1((x - 256.0) / 512.0 * scale, (y - 256.0) / 512.0 * scale) - equation2((x - 256.0) / 512.0 * scale, (y - 256.0) / 512.0 * scale));
}
void main() {
  float n = calc(gl_FragCoord.x, gl_FragCoord.y);
  gl_FragColor = gradient(n);
}