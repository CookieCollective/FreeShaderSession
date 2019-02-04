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


#define PI 3.14159
#define TAU 2. * PI
#define REP(p, r) (mod(p + r/2., r) - r /2.)

float sdSphere( vec3 p, float s )
{
  return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0))
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 d = abs(p) - b;
  return length(max(d,0.0)) - r
         + min(max(d.x,max(d.y,d.z)),0.0); // remove this line for an only partially signed sdf 
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdRoundedCylinder( vec3 p, float ra, float rb, float h )
{
    vec2 d = vec2( length(p.xz)-2.0*ra+rb, abs(p.y) - h );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0)) - rb;
}

float sdPlane( vec3 p, vec4 n )
{
  // n must be normalized
  return dot(p,n.xyz) + n.w;
}

float subtraction( float d1, float d2, float k ) 
{
  float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
  return mix( d2, -d1, h ) + k*h*(1.0-h); }

float intersection( float d1, float d2, float k ) 
{
  float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
  return mix( d2, d1, h ) + k*h*(1.0-h); }

vec3 lookAt (vec3 eye, vec3 at, vec2 uv) 
{
  vec3 forward = normalize(at - eye);
  vec3 right = normalize(cross(forward, vec3(0,1,0)));
  vec3 up = normalize(cross(right, forward));
  return normalize(forward + right * uv.x + up * uv.y);
}


vec2 modA(vec2 p, float r)
{
  float a = atan(p.y,p.x);

  a = mod(a + PI, TAU/r) - PI;

  return length(p) * vec2(cos(a),sin(a));
}

mat2 rot(float a)
{
  float ca = cos(a);
  float sa = sin(a);
  return mat2(ca,-sa,sa,ca);
}

float ease(float t)
{
  return floor(t) + sin(fract(t) * PI - PI / 2.) * .5 + .5;
}

#define BPM (50. / 60.)


float clap = 0.;

 float id = 0.;

float map(vec3 p)
{

  vec3 cp = p;
  float dist = 1000.;
  float time = fGlobalTime;
  time = ease(time * .4) ;
    
  float bump = pow(fract(fGlobalTime + p.z * .2), 2.) + sin(p.z) * .5 + .5;

  bump += clap;

  p.y -= 10.;
  p.z += fGlobalTime * 5.;
  
  p.x += sin(fGlobalTime * 4. + p.z + p.y * .1);

  p.xy *= rot(p.z * .01);
  p = REP(p, 20.);

  p.xz *= rot(time * PI);

  p.x = abs(p.x);
  p.y += -p.x * .75;

  dist = min(dist, sdSphere(p, 2. - bump));

  p = cp;

  p.y += (sin(p.z) + sin(p.x)) * .2;

  p.y += 1.;
  float fl = p.y;

  if(fl < .01) id = 1.;

  dist = min(dist, fl);

  return dist;
}


float cd = 0.;
vec3 outPos;
float ray(vec3 cp, vec3 rd)
{
  float st = 0.;
  for(;st < 1.; st += 1./ 128.)
  {
    cd = map(cp);
    if(cd < .01) break;
    cp += rd * cd * .5;
  }

  outPos = cp;
  return st;
}


vec3 normal(vec3 p)
{
  vec2 e = vec2(.01,.0);

  return normalize(vec3(
  map(p - e.xyy) - map(p + e.xyy),
  map(p - e.yxy) - map(p + e.yxy),
  map(p - e.yyx) - map(p + e.yyx)
));
}

void main(void)
{
  vec2 uv = vec2(gl_FragCoord.x / v2Resolution.x, gl_FragCoord.y / v2Resolution.y);
  uv -= 0.5;
  uv /= vec2(v2Resolution.y / v2Resolution.x, 1);

  vec3 eye = vec3(0.,0.,-10.);
  vec3 rd = lookAt(eye, vec3(0.), uv);
  vec3 cp = eye;

  float dist = length(uv);

  float st = ray(cp,rd);

  clap = texture(texFFTSmoothed,.1).x;


  vec3 norm = normal(outPos);
  float li = dot(norm, vec3(-1.,-1.,1.));

  vec4 col = vec4(.69);
  col.xz *= rot(fGlobalTime + outPos.z * .01);
  out_color = mix(vec4(.1,.05,.2,1.), col,li * .9) * (1. - length(uv));
  float len = distance(outPos, eye);
  
  if(id == 1.)
    out_color = vec4(1.);

  out_color *= 1. - st;
//  out_color *= 1. - exp(-len);

}