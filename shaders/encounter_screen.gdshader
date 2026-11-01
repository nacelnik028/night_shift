shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float strength = 0.0;
void fragment() {
 vec2 uv = SCREEN_UV;
 float edge = length(uv-vec2(0.5));
 vec2 offset = (uv-vec2(0.5))*edge*strength*0.018;
 vec3 c = texture(screen_tex, uv+offset).rgb;
 c.r = texture(screen_tex, uv+offset+vec2(strength*0.002,0)).r;
 c.b = texture(screen_tex, uv+offset-vec2(strength*0.002,0)).b;
 COLOR = vec4(c,1.0);
}
