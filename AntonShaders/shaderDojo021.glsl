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

#define PI 3.14159

vec2 modA(vec2 p, float n)
{
  float a = atan(p.y, p.x);
  a = mod(a /PI, 2. / n) * PI;

  return vec2(cos(a),sin(a)) * length(p);
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float sdCube(vec3 p)
{
  vec3 d = abs(p) - 1.;
  return length(max(d,0.0)) - .15
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float id = 0.;

float map(vec3 p)
{
  float dist = 1000.;
  vec3 cp = p;

  float time = fGlobalTime + p.z * .1;

  float tRad = 2. + fract(p.z/ 10000. + time * 1.) * .1;

  p.z += time;

  float tangle = .4 + sin(p.z * .05 * .0125) * .1;

  p.xy*= rot(p.z * tangle);

  p.xy = modA(p.xy, 5.);

  p.yx -= tRad;

  dist = min(dist,length(p.xy) - .4);

  p = cp;
  p.xy*= rot(p.z * -tangle );

  p.xy = modA(p.xy, 5.);

  p.yx -= tRad;

  dist = min(dist,length(p.xy) - .4);

  p = cp;

  p.z -= 20.;
  
  p.xy *= rot(fGlobalTime);
  p.xz *= rot(fGlobalTime * .7);
  p.zy *= rot(fGlobalTime * .8);

  p *= 1. - pow(fract(fGlobalTime ),2.) * .1;

  float cu = sdCube(p);
  if(cu < .01) id = 1.;

  dist = min(dist, cu);

  return dist;
}

vec3 normal(vec3 p)
{
  float b = map(p);
  vec2 e = vec2(.01,.0);
  return normalize(
    vec3( 
      b - map(p + e.xyy),
      b - map(p + e.yxy),
      b - map(p + e.yyx)
    )
  );
}

void ray(inout vec3 cp, in vec3 rd, out float cd, out float di)
{
  float st = 0.;
  cd = 0.;
  di = 0.;
  for(;st < 1.; st += 1./128.) 
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += cd * rd * .5;
    di += cd * .5;
  }
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 ro = vec3(0.,0.,-10.);
  vec3 rd = normalize(vec3(uv,1.));
  vec3 cp = ro;

  float cd, di;
  ray(cp,rd,cd,di);

  out_color = vec4(1.);

  if(cd < .01)
  {

    if(id == 1.)
    {
      out_color = vec4(.4, .4,.1,1.);
    }

    vec3 norm = normal(cp);
    
    vec3 ld = vec3(0.,0.,1.);
    float li = dot(norm, ld);

    vec4 lCol = vec4(.4,.01,.9,1.);

    if(id == 0.)
{
    li = 1. - li;
    li = pow(li, 2.);
}

    out_color = mix(out_color, lCol, li);
  }
}