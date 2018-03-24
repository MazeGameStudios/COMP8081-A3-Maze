#version 300 es
// Input vertex data, different for all executions of this shader.
layout(location = 0) in highp vec4 position; //attribute - per vertex
layout(location = 1) in lowp vec2 vertexUV;
out vec2 UV;

// Values that stay constant for the whole mesh. uniform - per object.
uniform mat4 MV; //Model View
uniform mat4 P; //Perspective


void main(void){
    // UV of the vertex. No special space for this one.
    UV = vertexUV;
    
    // Output position of the vertex, in clip space : MVP * position
    gl_Position = P * MV * position;
}


