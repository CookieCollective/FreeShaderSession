#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D cookie;
uniform sampler2D descartes;
uniform sampler2D texNoise;
uniform sampler2D texTex2;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

vec4 plas( vec2 v, float time )
{
  float c = 0.5 + sin( v.x * 10.0 ) + cos( sin( time + v.y ) * 20.0 );
  return vec4( sin(c * 0.2 + cos(time)), c * 0.15, cos( c * 0.1 + time / .4 ) * .25, 1.0 );
}

mat2 rotation(float a)
{
  float cosA = cos(a);
  float sinA = sin(a);
  return mat2(cosA,-sinA,sinA,cosA);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  //uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  //out_color = texture(texFFT, uv.x) * texture(cookie, uv.xy);

  uv *= rotation(texture(texFFT, uv.x).x * 200.0 * pow(.1  +sin(fGlobalTime + uv.x * 3.) * .45 + .55, 2.));

  out_color = texture(cookie, uv.xy);
}
