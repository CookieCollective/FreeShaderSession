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


mat2 rot(float a)
{
  float ca  = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

#define time (fGlobalTime)

float map(vec3 p, out float id)
{
  float dist = 1000.;
  id = 0.;
  vec3 cp = p;


  p.y -= time;
  p.xz *= rot(-p.y * .75 + sin(time * 1.1 - p.y) * .35);

  p.xz = abs(p.xz);

  p.z -= 4. + sin(time * 2. - p.y * 2.) * .2;
//  p.z *= 1.9;

  float co = max(p.x, p.z) - 1.;

  dist = min(dist,co);
  p = cp;
  dist = max(dist, -(length(p.xz)-2.75  + sin(p.y)*1.5));

  p = cp;
  float fl = p.y;
  if(fl < .01)
    id = 1.;


  dist = min(dist, fl);

  return dist;
}


float ray(inout vec3 cp, vec3 rd, out float id)
{
  float st = 0.;
  float cd = 0.;
  for(; st < 1.; st += 1./256.)
  {
    cd = map(cp, id);
    if(cd < .01) break;
    cp += rd * cd * .125;
  }

  return st;
}

vec3 lookAt(vec3 eye, vec3 tar, vec2 uv)
{
  vec3 dir = normalize(tar - eye);
  vec3 ri = cross(dir,vec3(0.,1.,0.));
  vec3 up = cross(ri,dir);
  return normalize(vec3(dir + ri * uv.x + up * uv.y));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,18.,-25.);
  eye.xz *= rot(time * .1);

  vec3 tar = vec3(0.,5.,0.);
  vec3 rd = lookAt(eye,tar,uv);
  vec3 cp = eye;
  float id = 0.;
  float st = ray(cp,rd,id);

  float dist = exp(-distance(eye,cp) * .05);
  
  out_color = mix(vec4(1.),vec4(.1,.05,.2,1.), id);

  out_color *= step(st,.9);

  out_color = mix(out_color, vec4(0.),dist);
}