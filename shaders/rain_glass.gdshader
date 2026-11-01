shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec4 tint : source_color = vec4(0.22, 0.36, 0.39, 0.08);
uniform bool animate_rain = true;
void fragment() {
 vec2 p = UV * vec2(55.0, 9.0);
 float column = floor(p.x);
 float seed = fract(sin(column * 127.1) * 43758.5453);
 float t = animate_rain ? TIME : 0.0;
 float trail = pow(max(0.0, 1.0 - abs(fract(p.x)-0.5)*13.0), 2.0);
 float drop = pow(fract(p.y + t*(0.3+seed*0.4) + seed*8.0), 10.0);
 float water = trail * drop;
 ALBEDO = tint.rgb + water * 0.22;
 ALPHA = tint.a + water * 0.28;
 ROUGHNESS = 0.14;
 SPECULAR = 0.7;
}
