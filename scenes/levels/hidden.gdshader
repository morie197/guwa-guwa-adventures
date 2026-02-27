shader_type canvas_item;

uniform sampler2D fow_mask: filter_nearest, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

uniform vec2 map_size;
uniform vec2 map_offset;
render_mode unshaded;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec2 global_uv = (world_pos - map_offset) / map_size;
	
    float mask_value = texture(fow_mask, global_uv).r;
    
    COLOR = fog_color;
    COLOR.a = 1.0 - mask_value; 
}