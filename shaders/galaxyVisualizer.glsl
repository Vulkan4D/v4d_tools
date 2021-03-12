precision highp float;

uniform vec2 u_resolution;

const int N = 40;
const int CHART_ZOOM = N*20;
const float MAX_POS = 10.0;
const float MIN_POS = -MAX_POS;
const vec3 OFFSET = vec3(110.500,35.907,0.415);
const int INTEGRAL = 0;

float plot(float v, float pct){
	float n = INTEGRAL>0? (0.5/float(INTEGRAL*2)) : max(0.002, 0.5/float(N*N*N));
	return step(pct-n, v) - step(pct+n, v);
}
vec3 _random3(vec3 pos) { // used for FastSimplex
	float j = 4096.0*sin(dot(pos,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}
float FastSimplex(vec3 pos) {
	const float F3 = 0.3333333;
	const float G3 = 0.1666667;

	vec3 s = floor(pos + dot(pos, vec3(F3)));
	vec3 x = pos - s + dot(s, vec3(G3));

	vec3 e = step(vec3(0.0), x - x.yzx);
	vec3 i1 = e * (1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy * (1.0 - e);

	vec3 x1 = x - i1 + G3;
	vec3 x2 = x - i2 + 2.0 * G3;
	vec3 x3 = x - 1.0 + 3.0 * G3;

	vec4 w, d;

	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);

	w = max(0.6 - w, 0.0);

	d.x = dot(_random3(s), x);
	d.y = dot(_random3(s + i1), x1);
	d.z = dot(_random3(s + i2), x2);
	d.w = dot(_random3(s + 1.0), x3);

	w *= w;
	w *= w;
	d *= w;

	return (dot(d, vec4(52.0)));
}


float QuickNoise(vec3 pos) {
	return fract(sin(dot(pos, vec3(13.657,9.558,11.606))) * 24097.524);
}

vec3 Noise3(vec3 pos) { // used for FastSimplex
	float j = 4096.0*sin(dot(pos,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

float easeOut(float t) {
	return sin(t * 3.14159265459 * 0.5);
}
float easeIn(float t) {
	return 1.0 - cos(t * 3.14159265459 * 0.5);
}
float clamp01(float v) {
	return max(0.0, min(1.0, v));
}

const int octaves = 3;
float FastSimplexFractal(vec3 pos) {
	float amplitude = 0.5333333333;
	float frequency = 1.0;
	float f = FastSimplex(pos * frequency);
	if (octaves > 1) for (int i = 1; i < octaves; ++i) {
		amplitude /= 2.0;
		frequency *= 2.0;
		f += amplitude * FastSimplex(pos * frequency);
	}
	return f;
}


struct GalaxyInfo {
	float spiralCloudsFactor;
	float swirlTwist;
	float swirlDetail;
	float coreSize;
	float cloudsSize;
	float cloudsFrequency;
	float squish;
	float attenuationCloudsFrequency;
	float attenuationCloudsFactor;
	vec3 noiseOffset;
	float irregularities;
	// vec3 position;
	// mat4 rotation;
};

GalaxyInfo GetGalaxyInfo(vec3 galaxyPosition) {
	GalaxyInfo info;
	float type = QuickNoise(galaxyPosition / 10.0);
	if (type < 0.2) {
		// Elliptical galaxy (20% probability)
		info.spiralCloudsFactor = 0.0;
		info.coreSize = QuickNoise(galaxyPosition);
		info.squish = QuickNoise(galaxyPosition+vec3(-0.33,-0.17,-0.51)) / 2.0;
	} else {
		if (type > 0.3) {
			// Irregular galaxy (70% probability, within spiral)
			info.irregularities = QuickNoise(galaxyPosition+vec3(-0.65,0.69,-0.71));
		} else {
			info.irregularities = 0.0;
		}
		// Spiral galaxy (80% probability, including irregular, only 10% will be regular)
		vec3 n1 = Noise3(galaxyPosition+vec3(0.01,0.43,-0.55)) / 2.0 + 0.5;
		vec3 n2 = Noise3(galaxyPosition+vec3(-0.130,0.590,-0.550)) / 2.0 + 0.5;
		vec3 n3 = Noise3(galaxyPosition+vec3(0.510,-0.310,0.512)) / 2.0 + 0.5;
		info.spiralCloudsFactor = n1.x;
		info.swirlTwist = n1.y;
		info.swirlDetail = n1.z;
		info.coreSize = n2.x;
		info.cloudsSize = n2.y;
		info.cloudsFrequency = n2.z;
		info.squish = n3.x;
		info.attenuationCloudsFrequency = n3.y;
		info.attenuationCloudsFactor = n3.z;
		info.noiseOffset = Noise3(galaxyPosition);
	}
	if (info.spiralCloudsFactor > 0.0 || info.squish > 0.2) {
		vec3 axis = normalize(Noise3(galaxyPosition+vec3(-0.212,0.864,0.892)));
		float angle = QuickNoise(galaxyPosition+vec3(0.176,0.917,1.337)) * 3.14159265459;
		float s = sin(angle);
		float c = cos(angle);
		float oc = 1.0 - c;
		// info.rotation = mat4(
		// 	oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 0.0,
		// 	oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
		// 	oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c, 0.0,
		// 	0.0, 0.0, 0.0, 1.0
		// );
	}
	return info;
}

float GalaxyStarDensity(in vec3 pos, in GalaxyInfo info) {
	float len = length(pos);
	if (len > 1.0) return 0.0;

	// Rotation
	// if (info.spiralCloudsFactor > 0.0 || info.squish > 0.2) pos = (info.rotation * vec4(pos, 1.0)).xyz;

	float squish = info.squish * 50.0;
	float lenSquished = length(pos*vec3(1.0, squish + 1.0, 1.0));
	float radiusGradient = 1.0 - pow(clamp01(len + abs(pos.y)*squish), 5.0);

	float core = clamp01(pow(1.0-lenSquished/info.coreSize, 5.0) + pow(1.0-lenSquished/info.coreSize, 10.0));
	if (core + radiusGradient <= 0.0) return 0.0;
	float finalDensity = core + pow(max(0.0, radiusGradient - 0.2), 10.0);

	if (info.spiralCloudsFactor == 0.0) {
		return finalDensity;
	}

	vec3 noiseOffset = info.noiseOffset * 65.4105;

	// Irregular
	if (info.irregularities > 0.0) {
		vec3 irregular = info.noiseOffset/2.0+.5;
		pos = mix(pos, pos*irregular, info.irregularities);
		info.spiralCloudsFactor = mix(info.spiralCloudsFactor, sin(irregular.y), info.irregularities);
		info.swirlTwist = mix(info.swirlTwist, irregular.x, info.irregularities);
		info.cloudsSize = mix(info.cloudsSize, irregular.y, info.irregularities);
		info.attenuationCloudsFrequency = mix(info.attenuationCloudsFrequency, irregular.z, info.irregularities);
		info.attenuationCloudsFactor = mix(info.attenuationCloudsFactor, irregular.x, info.irregularities);
		core += clamp01(pow(1.0-length(pos+info.noiseOffset)/info.coreSize*irregular.x, (sin(irregular.x)+1.0)*3.0));
		finalDensity += core * pow(max(0.0, radiusGradient), 1.5*irregular.x+1.0);
	}

	// Spiral
	float swirl = len * info.swirlTwist * 10.0;
	float spiralNoise = FastSimplexFractal((vec3(
		pos.x * cos(swirl) - pos.z * sin(swirl),
		pos.y * (squish * 0.0 + 1.0),
		pos.z * cos(swirl) + pos.x * sin(swirl)
	)+noiseOffset)*info.cloudsFrequency*5.0)/2.0+0.5;
	float spirale = clamp01(pow(spiralNoise, (1.1-info.swirlDetail)*5.0) + (info.cloudsSize*1.5) - len*1.5 - (abs(pos.y)*squish*10.0)) * radiusGradient;
	finalDensity += 1.0-pow(1.0-spirale, info.spiralCloudsFactor*4.0);
	if (finalDensity <= 0.0) return 0.0;
    
    finalDensity *= min(1.0, FastSimplexFractal(pos * 234.31)/2.0+0.8);

	// Attenuation Clouds
	float attenClouds = pow(clamp01(1.0-abs(FastSimplexFractal((vec3(
		pos.x * cos(swirl / 2.5) - pos.z * sin(swirl / 2.5),
		pos.y * (squish * 2.0 + 1.0),
		pos.z * cos(swirl / 2.5) + pos.x * sin(swirl / 2.5)
	)+noiseOffset)*info.attenuationCloudsFrequency*20.0))-core*3.0) * easeIn(radiusGradient), (3.0-info.attenuationCloudsFactor*2.0)) * info.attenuationCloudsFactor * 2.0;
	if (info.attenuationCloudsFactor > 0.0) finalDensity -= attenClouds * clamp01((FastSimplex((pos+info.noiseOffset)*info.attenuationCloudsFrequency*9.0)/2.0+0.5) * radiusGradient - (abs(pos.y)*squish*3.0));

	return finalDensity;
}

vec3 GalaxyStarColor(in vec3 pos, in GalaxyInfo info) {
	vec4 starType = normalize(vec4(
		/*red*/		QuickNoise(pos+info.noiseOffset+vec3(1.337,0.612,1.065)) * 0.5+pow(1.0-length(pos), 4.0)*2.0,
		/*yellow*/	QuickNoise(pos+info.noiseOffset+vec3(0.176,1.337,0.099)) * 1.4,
		/*blue*/	QuickNoise(pos+info.noiseOffset+vec3(1.337,0.420,1.099)) * 0.8+pow(length(pos), 2.0)*5.0,
		/*white*/	QuickNoise(pos+info.noiseOffset+vec3(1.337,1.185,0.474)) * 1.0 
	));
	return normalize((normalize(
		/*red*/		vec3( 1.0 , 0.4 , 0.2 ) * starType.x +
		/*yellow*/	vec3( 1.0 , 1.0 , 0.3 ) * starType.y +
		/*blue*/	vec3( 0.2 , 0.4 , 1.0 ) * starType.z +
		/*white*/	vec3( 1.0 , 1.0 , 1.0 ) * starType.w ))
		+ Noise3(pos * 64.31)/2.0);
}

void main() {
	vec2 st = gl_FragCoord.xy/u_resolution.xy;
	vec4 finalColor;

	GalaxyInfo info;
	/*float*/info.spiralCloudsFactor = 0.5;
	/*float*/info.swirlTwist = 4.0;
	/*float*/info.swirlDetail = 0.01;
	/*float*/info.coreSize = 0.25;
	/*float*/info.cloudsSize = 0.6;
	/*float*/info.cloudsFrequency = 0.5;
	/*float*/info.squish = 1.17;
	/*float*/info.attenuationCloudsFrequency = 0.0;
	/*float*/info.attenuationCloudsFactor = 0.0;
	/*vec3*/info.noiseOffset = vec3(0.3, 0.4, 0.5);
	/*float*/info.irregularities = 0.3;
	// /*vec3*/info.position = vec3(0.0);
	// /*mat4*/info.rotation = mat4(1.0);

	vec3 pos = vec3(st.s-0.5, 0.0, st.t-0.5) * 2.0; // top
	// pos = vec3(st.s-0.5, st.t-0.5, 0.0) * 2.0; // side
	float density = GalaxyStarDensity(pos, info);
	gl_FragColor = vec4(GalaxyStarColor(pos, info) * density, 1.0);
}
