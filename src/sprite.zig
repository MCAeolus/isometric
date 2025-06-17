const std = @import("std");
const globals = @import("globals.zig");
const rl = globals.Raylib;

pub const Sprite = struct {
    textureSheet: rl.Texture2D,
    rectSrc: rl.Rectangle,
    rectH: u32,
    rectW: u32,
    numFramesX: u32,
    numFramesY: u32,
    frame: u32 = 0,
    maxFrame: u32,
    frameDuration: f32,
    curDuration: f32 = 0,
    frameRangeMin: u32,
    frameRangeMax: u32,
    bounce: bool = false,
    dir: i32 = 1,

    pub fn NextFrame(sprite: *Sprite) void {
        if (sprite.bounce and sprite.frameRangeMax - sprite.frameRangeMin > 0) {
            if (sprite.bounce and sprite.frame == sprite.frameRangeMax) {
                sprite.dir = -1;
            } else if (sprite.bounce and sprite.frame == sprite.frameRangeMin) {
                sprite.dir = 1;
            }
            sprite.frame = @as(u32, @intCast(@as(i32, @intCast(sprite.frame)) + sprite.dir));
        } else {
            sprite.frame = @mod(sprite.frame + 1, sprite.frameRangeMax + 1); // (frame + 1) % maxframe
        }
        const realFrame = sprite.frame + sprite.frameRangeMin;
        const sheetX = @mod(realFrame, sprite.numFramesX) * sprite.rectW; // (frame % rectSize) * rectW
        const sheetY = @mod(@divFloor(realFrame, sprite.numFramesX), sprite.numFramesY) * sprite.rectH;
        //std.debug.print("cur frame: {d}, cur w: {d}, cur h: {d}\n", .{ sprite.frame, sheetX, sheetY });
        sprite.rectSrc.x = @floatFromInt(sheetX);
        sprite.rectSrc.y = @floatFromInt(sheetY);
    }

    pub fn Update(sprite: *Sprite, dt: f32) void {
        sprite.curDuration += dt;
        if (sprite.curDuration < sprite.frameDuration) {
            return;
        }
        sprite.curDuration = 0;
        sprite.NextFrame();
    }

    pub fn SetBounce(sprite: *Sprite, bounce: bool) void {
        sprite.bounce = bounce;
    }

    pub fn SetFrameRange(sprite: *Sprite, min: u32, max: u32, duration: f32) void {
        sprite.frameRangeMin = min;
        sprite.frameRangeMax = max - min;
        sprite.frameDuration = duration;
    }

    pub fn ResetFrameRange(sprite: *Sprite) void {
        sprite.frameRangeMin = 0;
        sprite.frameRangeMax = sprite.maxFrame; //todo: 1off?
    }
};

pub fn NewSprite(textureSheet: rl.Texture2D, spriteW: u32, spriteH: u32, maxFrames: u32, frameDuration: f32) Sprite {
    var finalFrames = maxFrames;
    const numFramesX = @max(1, @divFloor(@as(u32, @intCast(textureSheet.width)), spriteW));
    const numFramesY = @max(1, @divFloor(@as(u32, @intCast(textureSheet.height)), spriteH));

    if (maxFrames == 0) {
        finalFrames = numFramesX * numFramesY;
    }
    std.debug.print("final frames: {d}, sheetw: {d} sheeth: {d}\n", .{ finalFrames, textureSheet.width, textureSheet.height });
    return .{
        .textureSheet = textureSheet,
        .rectSrc = rl.Rectangle{ .x = 0, .y = 0, .width = @floatFromInt(spriteW), .height = @floatFromInt(spriteH) },
        .maxFrame = finalFrames,
        .rectW = spriteW,
        .rectH = spriteH,
        .numFramesX = numFramesX,
        .numFramesY = numFramesY,
        .frameDuration = frameDuration,
        .frameRangeMin = 0,
        .frameRangeMax = finalFrames, //1 off?
    };
}
