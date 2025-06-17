#version 330

in vec3 fragPosition;
in vec2 fragTexCoord;
//in vec3 fragColor;
in vec3 fragNormal;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

#define MAX_LIGHTS  64
#define LIGHT_POINT 0
#define LIGHT_DIRECTIONAL 1

struct Light {
    int enabled;
    int type;
    vec3 position;
    vec3 target;
    vec4 color;
    float intensity;
};

uniform Light lights[MAX_LIGHTS];
uniform vec4 ambient;
uniform vec3 viewPos;

void main() {
    vec4 texelColor = texture(texture0, fragTexCoord);
    vec3 lightDot = vec3(0.0);
    vec3 normal = normalize(fragNormal);
    vec3 viewD = normalize(viewPos - fragPosition);
    vec3 specular = vec3(0.0);

    //vec4 tint = colDiffuse * fragColor;

    for (int i = 0; i < MAX_LIGHTS; i++) {
        if (lights[i].enabled == 1) {
            vec3 light = vec3(0.0);
            float attenuation = 1.0;
            if (lights[i].type == LIGHT_DIRECTIONAL) {
                light = -normalize(lights[i].target - lights[i].position);
            }

            if (lights[i].type == LIGHT_POINT) {
                light = normalize(lights[i].position - fragPosition);
                float distance = length(lights[i].position - fragPosition);
                attenuation = 1.0/(distance*distance*0.23);
            }
            float NdotL = max(dot(normal, light), 0.0);
            lightDot += lights[i].color.rgb*lights[i].intensity*attenuation*NdotL;

            float specCo = 0.0;
            if (NdotL >0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0); //16 is shine amt
            specular += specCo;
        }
    }

    //colDiffuse `was` tint
    finalColor = (texelColor * ((colDiffuse + vec4(specular, 1.0))*vec4(lightDot, 1.0)));
    finalColor *= texelColor * (ambient/10.0)*colDiffuse;
    //gamma
    finalColor = pow(finalColor, vec4(1.0/2.2));
}
