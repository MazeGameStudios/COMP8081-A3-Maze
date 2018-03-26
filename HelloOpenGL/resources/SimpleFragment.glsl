#version 300 es

precision highp float;
in vec2 UV;
in vec3 v_position;
out vec4 o_fragColor;out lowp vec3 color;

uniform sampler2D texSampler;
uniform vec4 ambientColor;
uniform bool spotlight;
uniform float spotlightCutoff;
uniform vec4 spotlightColor;
uniform bool fog;
uniform vec4 fogColor;
uniform float fogEnd;
uniform float fogDensity;
uniform bool fogUseExp;

void main() {
    vec4 linearColor = ambientColor;
    
    if (spotlight) {
        float spotlightValue = dot(normalize(v_position), vec3(0.0, 0.0, -1.0));
        if (spotlightValue > spotlightCutoff) {
            linearColor += spotlightColor * sqrt((spotlightValue - spotlightCutoff) / (1.0 - spotlightCutoff));
        }
    }
    
    linearColor *= texture(texSampler, UV);
    
    if (fog) {
        float fogMix;
        if (fogUseExp) {
            fogMix = exp(-length(v_position) * fogDensity);
        } else {
            fogMix = max(0.0, 1.0 - length(v_position) / fogEnd);
        }
        linearColor = mix(fogColor, linearColor, fogMix);
    }
    
    o_fragColor = linearColor;
}



/*
out lowp vec3 color;

in lowp vec2 UV;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main(void){
    // Output color = color of the texture at the specified UV
    color = texture( myTextureSampler, UV ).rgb;
}

*/
