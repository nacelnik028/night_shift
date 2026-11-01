shader_type canvas_item;
uniform bool interference = false;
uniform float dropout = 0.0;
uniform float face = 0.0;
uniform bool reduced = false;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.98,78.23)))*43758.5); }
void fragment() {
 float motion = reduced ? 0.0 : floor(TIME * 18.0);
 float n = hash(floor(UV*vec2(640.0,360.0))+motion);
 vec2 uv = UV;
 if (!reduced) { uv.x += sin(uv.y * 37.0 + TIME * 3.0) * 0.0007; }
 vec3 c = texture(TEXTURE, uv).rgb;
 float g = dot(c,vec3(0.299,0.587,0.114));
 float s = 0.94+0.06*sin(UV.y*680.0);
 vec3 result = vec3(0.63,1.0,0.78)*g*s+n*0.025;
 if (interference || dropout > 0.0) { result = vec3(0.015+n*(reduced ? 0.035 : 0.12)); }
 if (face > 0.0) {
  vec2 p = (UV-vec2(0.5,0.5))*vec2(1.0,0.65);
  float skull = 1.0-smoothstep(0.12,0.14,length(p));
  float eyes = (1.0-smoothstep(0.012,0.022,length(p-vec2(0.05,-0.02)))) + (1.0-smoothstep(0.01,0.02,length(p-vec2(-0.05,-0.03))));
  float mouth = 1.0-smoothstep(0.026,0.035,length((p-vec2(0.0,0.065))*vec2(1.0,0.5)));
  result += vec3(0.18,0.22,0.19)*skull - vec3(0.15)*(eyes+mouth);
 }
 COLOR = vec4(max(result, vec3(0.0)), 1.0);
}
