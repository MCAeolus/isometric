const std = @import("std");
pub const Raylib = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const sprite = @import("sprite.zig");
const Allocator = std.mem.Allocator;

const Screen = struct { width: c_int, height: c_int };

pub const GameState = struct { screen: Screen = .{ .width = 1920 / 2, .height = 1080 / 2 }, initialized: bool = false, camera: Raylib.Camera = .{}, camera_follow_distance: f32 = 7.0, gravity: f32 = -0.1 };

// this must also be updated in lighting.fs
pub const MaxLights = 64;

var state: GameState = .{};

pub fn GetGameState() *GameState {
    if (!state.initialized) {
        state = GameState{ .initialized = true };
    }
    return &state;
}
