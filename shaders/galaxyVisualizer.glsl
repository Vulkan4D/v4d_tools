precision highp float;

uniform vec2 u_resolution;

vec3 _random3(vec3 pos) { // used in FastSimplex
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

float clamp01(float v) {
	return max(0.0, min(1.0, v));
}

struct GalaxyInfo {
	float spiralCloudsFactor; // 0.0 to 2.0
	float swirlTwist; // -3.0 to +3.0 (typically between +- 0.2 and 1.5)
	float swirlDetail; // 0.0 to 1.0
	float cloudsSize; // 0.0 to 1.5
	float cloudsFrequency; // 0.0 to 2.0
	float squish; // 0.0 to 2.0 (typically between 0.3 and 1.5 for a spiral, and 0.0 for elliptical)
};

float GalaxyStarDensity(in vec3 pos, in GalaxyInfo info) {
	float len = dot(pos, pos);
	if (len > 1.0) return 0.0;

	float squish = info.squish * 65.;
	float lenSquished = length(pos*vec3(1.0, squish + 1.0, 1.0));
	float radiusGradient = (1.0-clamp01(len*5.0 + abs(pos.y)*squish))*1.002;

	// Core
	float core = pow(1.0 - lenSquished*1.84 + lenSquished, 50.0);
	float finalDensity = core + pow(max(0.0, radiusGradient), 50.0) / 2.0;

	// Spiral
	float swirl = len * info.swirlTwist * 40.0;
	float spiralNoise = FastSimplex(vec3(
		pos.x * cos(swirl) - pos.z * sin(swirl),
		pos.y,
		pos.z * cos(swirl) + pos.x * sin(swirl)
	) * info.cloudsFrequency * 4.0) / 2.0 + 0.5;
	float spirale = (pow(spiralNoise, (1.15-info.swirlDetail)*10.0) + info.cloudsSize - len - (abs(pos.y)*squish)) * radiusGradient;
	finalDensity += pow(spirale, 4.) * info.spiralCloudsFactor / 8.0;

	return finalDensity;
}

void main() {
	vec2 st = gl_FragCoord.xy/u_resolution.xy;

	GalaxyInfo info;
		info.spiralCloudsFactor = 1.0; // 0.0 to 2.0
		info.swirlTwist = 1.0; // -3.0 to +3.0 (typically between +- 0.2 and 1.5)
		info.swirlDetail = 1.0; // 0.0 to 1.0
		info.cloudsSize = 1.0; // 0.0 to 1.5
		info.cloudsFrequency = 1.0; // 0.0 to 2.0
		info.squish = 1.0; // 0.0 to 2.0 (typically between 0.3 and 1.5 for a spiral, and 0.0 for elliptical)

	vec3 pos = vec3(st.s-0.5, 0.0, st.t-0.5) * 2.0; // top
	// pos = vec3(st.s-0.5, st.t-0.5, 0.0) * 2.0; // side
	float density = GalaxyStarDensity(pos, info);
	gl_FragColor = vec4(vec3(density), 1.0);
	
	// if (density > 0.0) gl_FragColor = vec4(1);
	// else gl_FragColor = vec4(0);
}
