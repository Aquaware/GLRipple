attribute vec4 position;
attribute vec2 texCoord;

uniform mat4 projection;

varying vec2 texCoordVarying;

void main()
{
    //gl_Position = position;
    gl_Position = projection * position;

    texCoordVarying = texCoord;
}