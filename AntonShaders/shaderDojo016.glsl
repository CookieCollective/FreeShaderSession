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


float sdCube(vec3 p)
{
  vec3 d = abs(p) - 1.;
  return length(max(d, 0.)) + min(max(d.x, max(d.y,d.z)), 0.) - .2;
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float map(vec3 p)
{
  float dist = 1000.;
  vec3 cp = p;

  float time = fGlobalTime;


  p.xz *= rot(p.y);
  p.y += p.x * .5 + sin(p.y + fGlobalTime) * .5 + .5;


  float cu = 1000.;

  for(float i = 1.; i <= 4.; ++i)
  {
    float ad = sdCube(p);
    cu = min(cu, ad);

    p *= 1.1;
    p.xz *= rot(i * .3 + time * i);
    p.yz *= rot(i + time);
  }

  p = cp;
  float rim = length(p)-1.;
  rim = max(-rim, (length(p )- 2.5));

  dist = min(dist, cu);

  dist = max(dist,rim);

  return dist;
}


vec3 normal(vec3 p)
{
  vec2 e = vec2(0.,.01);
  return normalize(vec3(
  map(p + e.xxy) - map(p - e.xxy),
  map(p + e.xyx) - map(p - e.xyx),
  map(p + e.yxx) - map(p - e.yxx)
  
));
}

vec3 lookAt(vec3 eye, vec3 sub, vec2 uv)
{
  vec3 forward = normalize(sub - eye);
  vec3 right = normalize(cross(forward , vec3(0.,1.,0.)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = lookAt(eye, vec3(0.,0.,0.),uv);
  vec3 cp = eye;

  float st =0.;
  float cd = 0.; 
  for(;st < 1.; st += 1. / 128.)
{ 
    cd  = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
}

  if(cd < .01)
  {
    vec3 norm = normal(cp);
    float li = dot(norm, rd);


  li = 1. - pow(li,1.);
    vec4 col = norm.xyzz * 4.;
float time = fGlobalTime;
    col.xz *= rot(time + cp.y);
    col.xy *= rot(time + cp.z);
    col.yz *= rot(time + cp.x);
col = normalize(col);
  out_color = vec4(mix(vec4(0.), col,li));

  }

}