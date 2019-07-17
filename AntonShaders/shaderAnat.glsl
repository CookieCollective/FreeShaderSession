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

#define time fGlobalTime
layout(location = 0) out vec4 out_color; // out_color must be written in order to see anything

float ribbon(vec3 p) {
  float d = length(p.xy+vec2(cos(p.z)*1.,sin(p.z))*3.);
  return d;
}

vec2 path(float v) {
  return vec2(cos(v), sin(v));
}

float map(vec3 p) {
  float d = 0.;
  float s = 1.;
  vec3 pp = p;
  for(int i=0; i<7; i++) {
    d += dot(cos(p), sin(p.zxy))*s;
    p *= 2.;
    s *= .5;
    p += -time*.2;
  }
  return length(pp.xy)-2.+d;
}
#define saturate(x) clamp(x,0.,1.)
float hash(vec2 p) {
  return fract( sin(dot(p,vec2(64.,5132.)))*4242.);
}

mat2 rot(float v) {
  float a = cos(v);
  float b = sin(v);

  return mat2(a,b,-b,a);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0., fGlobalTime*2.)+vec3(path(time*.1)*.5,0.);
  vec3 rd = normalize(vec3(uv, 1.));
  rd.xy = rot(time*.1) * rd.xy;
  rd.xz = rot(time*.2) * rd.xz;


  vec3 col = vec3(1.);
  float jitt = hash(uv);
  for(float i=0.; i<1.; i += 1./32.) {
    float l = (1.-(i+jitt/32.))*20.;
    vec3 p = ro + rd * l;
    float d = map(p);

    vec3 c = pow(vec3(.2,.5,1.), vec3(exp(-d))) * exp(-d*5.)*3.;
    c += vec3(1.,.7,.5) * saturate(d-map(p+1.))*exp(-d*5.)*5.;
    c += vec3(1.,.7,.1) / (exp(ribbon(p)*10.)-.99)*20.;
    col = mix(col, c, vec3(saturate(d*(cos(time)*.45+.5))));
  }

  if (cos(length(uv)-time)>0. && cos(length(uv)-time)<0.5) {
    col = vec3(1.)-col;
  }

  out_color = vec4(col, 1.);
  }