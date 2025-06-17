#version 330

#define MAX_LIGHTS 32

in vec4 fragColor;
in vec3 fragPosition;
in vec2 fragTexCoord;
in vec3 fragNormal;
in vec2 scaledUV;

out vec4 finalColor;

uniform vec3 ambientColor;
uniform float ambientStrength;
uniform sampler2D texture0;
uniform int pixelresolution;

struct Light {
    vec3 position;
    vec4 color;
};

uniform Light lights[MAX_LIGHTS];

//vec3 lightPosition = vec3(0.0, 3.0, 4.0);

void main() {
    vec3 ambient = ambientStrength * ambientColor;
    //vec2 texcoord = vec2(dx * floor(fragTexCoord.x/dx), dy * floor(fragTexCoord.y/dy));
    //vec2 texcoord = vec2(floor((fragTexCoord.x * pixelresolution + 0.5) / pixelresolution), floor((fragTexCoord.y * pixelresolution + 0.5) / pixelresolution));

    vec2 texCoord = round(fragTexCoord * 8.0) / 8.0;

    vec4 texelColor = texture(texture0, texCoord);
    
    vec3 norm = normalize(fragNormal);
    vec3 sumDiffuse = vec3(0.0); //accumulates total from lights

    for (int i = 0; i < MAX_LIGHTS; i++) {
        vec3 lightDir = normalize(lights[i].position - fragPosition); //todo: hardcoded light
        float diffuseScalar = max(dot(norm, lightDir), 0.0); //NdotL with clipping at 0
        vec3 diffuse = diffuseScalar * lights[i].color.rgb;

        sumDiffuse += diffuse;
    }    
    
    vec3 result = (ambient + sumDiffuse) * fragColor.rgb * texelColor.rgb; // sum together the total luminence of diffuse and ambience, then scale the rgb channels
    finalColor = vec4(result, fragColor.a); //passthrough alpha channel
}
