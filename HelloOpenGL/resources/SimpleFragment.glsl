#version 300 es
// Interpolated values from the vertex shaders
//in lowp vec3 fragmentColor;
out lowp vec3 color;

in lowp vec2 UV;

// Values that stay constant for the whole mesh.
uniform sampler2D myTextureSampler;

void main(void){
    // Output color = color of the texture at the specified UV
    color = texture( myTextureSampler, UV ).rgb;
}

