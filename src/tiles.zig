const std = @import("std");
const rl = @cImport(@cInclude("raylib.h"));

pub fn LoadTileset(source: []const u8, tile_w: u16, tile_h: u16) void {
    const texture = rl.LoadTexture(source);
}
