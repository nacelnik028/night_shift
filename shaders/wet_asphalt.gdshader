shader_type spatial;
render_mode diffuse_burley;
varying vec3 world_pos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
 vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec2 p=world_pos.xz;
 float aggregate=noise(p*90.0);
 float puddle=smoothstep(0.39,0.61,noise(p*0.52));
 ALBEDO=vec3(0.14,0.17,0.18)*(0.8+aggregate*0.35)*(1.0-puddle*0.22);
 ROUGHNESS=mix(0.78,0.20,puddle);
 SPECULAR=mix(0.30,0.58,puddle);
 float wave=sin(length(fract(p*1.7)-0.5)*65.0-TIME*7.0)*0.014*puddle;
 NORMAL_MAP=vec3(0.5+wave,0.5+wave*0.6,1.0);
 NORMAL_MAP_DEPTH=0.10;
 // A bounded authored canopy-light sheen supplements Compatibility specular.
 // It is intentionally subtle; this does not require an SSR/reflection viewport.
 float grazing=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),3.0);
 float canopy=exp(-pow((p.y-19.0)/2.5,2.0))*exp(-pow(p.x/9.0,6.0));
 float strip=exp(-pow((abs(p.x)-6.0)/0.50,2.0));
 EMISSION=vec3(0.12,0.25,0.22)*canopy*strip*puddle*grazing*0.65;
}
