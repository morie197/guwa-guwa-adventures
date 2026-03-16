shader_type canvas_item;

//uniform vec4 shine_color : source_color = vec4(1.0);
//uniform float shine_speed : hint_range(0.0, 10.0) = 1.0;
//uniform float shine_size : hint_range(0.01, 1.0) = 0.1;
//uniform vec4 light_up_color : source_color = vec4(1.0);

uniform float shine_speed : hint_range(0.0, 10.0) = 2.0;
uniform float shine_width : hint_range(0.0, 1.0) = 0.2;
uniform float shine_intensity : hint_range(0.0, 5.0) = 1.0; // Over 1.0 for Bloom!

uniform float global_brighten : hint_range(0.0, 1.0) = 0.2; // How much the whole sprite lights up
uniform float line_intensity : hint_range(0.0, 5.0) = 0.5; // The extra brightness of the line

uniform vec4 uv_offset : source_color = vec4(0.0, 0.0, 0.0, 1.0);



//
//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
	//COLOR = texture(TEXTURE, UV); 
    //float shine = step(1.0 - shine_size, 0.1 + 0.9 * sin(UV.x - UV.y + TIME * shine_speed));
	//if ( sin(TIME * shine_speed) > -0.5) {
		//COLOR.rgb = mix(COLOR.rgb, light_up_color.rgb, sin(TIME * shine_speed));
		////COLOR = texture(TEXTURE, UV);
	//}
    //COLOR.rgb = mix(COLOR.rgb, shine_color.rgb, shine * shine_color.a);
	
	// 1. Get the base color from the Sprite
   vec4 base_color = texture(TEXTURE, UV);
    
    // 1. Create the moving wave (0.0 to 1.0 range)
    float wave = 0.1 + 0.9 * sin((UV.x - UV.y) + TIME * shine_speed);
    
    // 2. Create a sharp line mask
    float line_mask = step(1.0 - shine_width, wave);
    
    // 3. Create a smooth 'glow' for the whole sprite that peaks with the line
    // This makes the whole sprite brighten as the 'wave' passes through
    float total_brightness = (wave * global_brighten) + (line_mask * line_intensity);
    
    // 4. Apply brightness, keeping it confined to the sprite's shape (alpha)
    vec3 bright_color = (base_color.rgb + uv_offset.rgb) + (total_brightness * base_color.a);
    
    COLOR = vec4(bright_color, base_color.a);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
