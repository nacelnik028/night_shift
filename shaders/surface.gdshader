shader_type spatial;
render_mode diffuse_burley;
uniform vec4 base_color : source_color = vec4(0.3, 0.35, 0.32, 1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.0;
uniform float grain_scale = 32.0;
uniform float grime = 0.18;
uniform bool tile_surface = false;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i = floor(p); vec2 f = fract(p); f = f*f*(3.0-2.0*f);
 return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
 vec2 p = world_pos.xz + world_pos.yy * 0.71;
 float speckle = noise(p * grain_scale);
 float stains = smoothstep(0.36, 0.76, noise(p * 0.8));
 float wet = wetness * smoothstep(0.35, 0.7, noise(p * 0.42));
 ALBEDO = base_color.rgb * (0.89 + speckle * 0.12 - stains * grime) * (1.0 - wet * 0.24);
 ROUGHNESS = mix(0.82, 0.12, wet);
 SPECULAR = mix(0.3, 0.85, wet);
 if (tile_surface) {
  vec2 tile = world_pos.xz / 0.62;
  vec2 edge = min(fract(tile), 1.0 - fract(tile));
  float grout = 1.0 - smoothstep(0.006, 0.018, min(edge.x, edge.y));
  float tone = hash(floor(tile)) * 0.09;
  ALBEDO *= 0.91 + tone;
  ALBEDO = mix(ALBEDO, vec3(0.17, 0.19, 0.16), grout * 0.65);
  ROUGHNESS = mix(0.43 + stains * 0.22, 0.89, grout);
  SPECULAR = 0.45;
 }
}
