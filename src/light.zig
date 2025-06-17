const std = @import("std");
const globals = @import("globals.zig");
const rl = globals.Raylib;

const MAX_LIGHTS = globals.MaxLights;

// declaration order MATTERS (lighting.fs)
pub const LightType = enum { POINT, DIRECTIONAL };

pub const Light = struct {
    type: LightType,
    enabled: bool,
    position: rl.Vector3,
    target: rl.Vector3,
    color: rl.Color,
    intensity: f32,
    //attenuation: f32,

    //shader buffer positions
    lEnabled: c_int,
    lType: c_int,
    lPosition: c_int,
    lTarget: c_int,
    lColor: c_int,
    lIntensity: c_int,
    //lAttenuation: c_int,
};

var lightLocation: i32 = 0;

pub fn CreateLight(lightType: LightType, position: rl.Vector3, target: rl.Vector3, color: rl.Color, intensity: f32, shader: rl.Shader) Light {
    if (lightLocation >= MAX_LIGHTS) {
        std.debug.panic("Surpassed maximum allowed lights.", .{});
    }

    const light: Light = .{
        .enabled = true,
        .type = lightType,
        .position = position,
        .target = target,
        .color = color,
        .intensity = intensity,
        .lEnabled = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].enabled", lightLocation)),
        .lType = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].type", lightLocation)),
        .lPosition = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].position", lightLocation)),
        .lTarget = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].target", lightLocation)),
        .lColor = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].color", lightLocation)),
        .lIntensity = rl.GetShaderLocation(shader, rl.TextFormat("lights[%i].intensity", lightLocation)),
    };

    //std.debug.print("Lighgt created: {any}", .{light});

    UpdateLightValues(shader, light);
    lightLocation += 1;
    return light;
}

pub fn UpdateLightValues(shader: rl.Shader, light: Light) void {
    rl.SetShaderValue(shader, light.lEnabled, &light.enabled, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, light.lType, &light.type, rl.SHADER_UNIFORM_INT);
    rl.SetShaderValue(shader, light.lPosition, &light.position.x, rl.SHADER_UNIFORM_VEC3);
    rl.SetShaderValue(shader, light.lTarget, &light.target.x, rl.SHADER_UNIFORM_VEC3);
    const color: [4]f32 = .{ @as(f32, @floatFromInt(light.color.r)) / 255.0, @as(f32, @floatFromInt(light.color.g)) / 255.0, @as(f32, @floatFromInt(light.color.b)) / 255.0, @as(f32, @floatFromInt(light.color.a)) / 255.0 };
    rl.SetShaderValue(shader, light.lColor, &color, rl.SHADER_UNIFORM_VEC4);
    rl.SetShaderValue(shader, light.lIntensity, &light.intensity, rl.SHADER_UNIFORM_FLOAT);
}
