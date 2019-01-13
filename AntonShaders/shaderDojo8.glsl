#version 410 core

uniform float fGlobalTime; // in seconds
uniform vec2 v2Resolution; // viewport resolution (in pixels)

uniform sampler1D texFFT; // towards 0.0 is bass / lower freq, towards 1.0 is higher / treble freq
uniform sampler1D texFFTSmoothed; // this one has longer falloff and less harsh transients
uniform sampler1D texFFTIntegrated; // this is continually increasing
uniform sampler2D texChecker;
uniform sampler2D texNoise;
uniform sampler2D texTex1;
uniform sampler2D texTex2;
uniform sampler2D texTex3;
uniform sampler2D texTex4;

layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float fbm(vec2 p)
{
  mat2 m = mat2(.8,-.6,.6,.8);
  p *= m;
  float acc = 0.;
  for(float i = 1.; i <8.; ++i)
  {
    acc += (sin(p.x * i) + cos(p.y * i)) * 8. / (i*.8 );
    p *= m; p += vec2( 10345.123, 9664.12374) + vec2(fGlobalTime * .25);
  }
  return acc;
}

float map(vec3 p)
{
  float dist  = 10000.;
  vec3 cp = p;
  p.y += 2.;

  float plan = p.y + fbm(p.xz) * .01;

  p.x += sin(p.z * .25 + fGlobalTime * .75);
  float cy = length(p.xy) - (1. - p.z * .05);


  dist = min(dist,cy);
  dist = max(dist, plan);

  return dist;
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv, 1.));
  vec3 cp = ro;

  float st = 0.; float cd = 0.;
  for(;st < 1.; st +=1./128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  out_color = mix(vec4(0.,0.,0.05,0.),vec4(1.,1.,1.,1.) * .85, clamp(1. - pow(length(uv * 13.),10.5) ,0.,1.)*.7 );

  if(cd < .01)
  out_color += vec4(1. - st);
}