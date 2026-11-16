shader_type spatial;

uniform sampler2D albedo_tex : source_color;
uniform sampler2D texture_mask : source_color, filter_linear_mipmap, repeat_enable;

void fragment() {
    vec4 albedo_color = texture(albedo_tex, UV);
    vec4 mask_tex = texture(texture_mask, UV);

    ALBEDO = albedo_color.rgb;
    // Use the red channel of the mask for alpha transparency
    ALPHA = mask_tex.r; 
}
