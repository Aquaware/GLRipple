uniform sampler2D samplerRGB;
varying highp vec2 texCoordVarying;

void main()
{
    gl_FragColor = texture2D(samplerRGB, texCoordVarying);
}

