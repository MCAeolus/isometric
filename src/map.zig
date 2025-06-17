const std = @import("std");
const globals = @import("globals.zig");
const rl = globals.Raylib;

pub const TileType = struct {
    model: rl.Model,
    mesh: rl.Mesh,
};

pub const Tile = struct {
    tileType: TileType,
};

pub const TYPE_GRASS = struct {};

//const tileTypes = [_]TileType{};

pub const Map = struct {
    width: u32,
    height: u32,
    tiles: []Tile,
    spawn: rl.Vector3,
    mapCenter: rl.Vector3,

    pub fn SetTile(map: *Map, x: u32, y: u32, tile: Tile) void {
        map.tiles[x + y * map.width] = tile;
    }

    pub fn GetTile(map: *Map, x: u32, y: u32) Tile {
        return map.tiles[x + y * map.width];
    }
};

fn LoadBasicTile(mesh: rl.Mesh, textureFile: [*c]const u8, shader: rl.Shader) TileType {
    var model = rl.LoadModelFromMesh(mesh);
    const texture = rl.LoadTexture(textureFile);
    model.materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].texture = texture;
    model.materials[0].shader = shader;
    model.transform = rl.MatrixRotateY(45 * rl.DEG2RAD);
    return .{
        .mesh = mesh,
        .model = model,
    };
}

fn DefineTileTypes(shader: rl.Shader) [2]TileType {
    return [_]TileType{ LoadBasicTile(rl.GenMeshCube(1, 1, 1), "resources/grass.png", shader), LoadBasicTile(rl.GenMeshCube(1, 1, 1), "resources/texel_checker.png", shader) };
}

pub fn LoadMap(file: []const u8, allocator: std.mem.Allocator, terrainShader: rl.Shader) anyerror!Map {
    const TILE_GRASS, const TILE_STONE = DefineTileTypes(terrainShader);

    const fd = try std.fs.cwd().openFile(file, .{});
    defer fd.close();

    var bufreader = std.io.bufferedReader(fd.reader());
    var stream_in = bufreader.reader();

    var buf: [1024]u8 = undefined;
    // read first line: size data, looks like w,h
    const wLine = try stream_in.readUntilDelimiterOrEof(&buf, ',');
    //std.debug.print("{s}\n", .{wLine});
    const w = try std.fmt.parseInt(u32, wLine.?, 10);
    const hLine = try stream_in.readUntilDelimiterOrEof(&buf, '\n');
    const h = try std.fmt.parseInt(u32, hLine.?, 10);

    if (w % 2 == 0 or h % 2 == 0) std.debug.print("Warn: map size is even\n", .{});

    const centerW = @ceil(@as(f32, @floatFromInt(w)) / 2);
    const centerH = @ceil(@as(f32, @floatFromInt(h)) / 2);
    const centeringVector = rl.Vector3{ .x = centerW, .y = 0, .z = centerH };
    std.debug.print("Map center: {d},{d}\n", .{ centerW, centerH });
    // allocate map 2d array
    var map: Map = .{
        .tiles = try allocator.alloc(Tile, w * h),
        .width = w,
        .height = h,
        .spawn = rl.Vector3One(),
        .mapCenter = centeringVector,
    };
    var curH: u32 = 0;
    while (try stream_in.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        //row parsing rules
        // - ignore spaces
        // - [] defines a row entry
        // - [1,2,3] defines the tile components of one row entry. Lowest->Highest y-axis (so we can store decoration, or a spawn, etc for each position)
        var curW: u32 = 0;
        var thisTile: Tile = undefined;
        for (line) |char| {
            if (char == ' ' or char == '[' or char == ',') continue;
            if (char == ']') {
                map.SetTile(curW, curH, thisTile);
                curW += 1;
                thisTile = undefined;
                continue;
            }
            // map chars in
            switch (char) {
                's' => { // spawn char
                    map.spawn = rl.Vector3{ .x = @floatFromInt(curH), .y = 1, .z = @floatFromInt(curW) };
                    //map.spawn = rl.Vector3Subtract(map.spawn, rl.Vector3{ .x = 0.5, .y = 0, .z = 0.5 });
                },
                'g' => { // grass
                    thisTile = .{
                        .tileType = TILE_GRASS,
                    };
                },
                't' => { //stone
                    thisTile = .{
                        .tileType = TILE_STONE,
                    };
                },
                else => {
                    std.debug.panic("Invalid character {c} at w={d} h={d}", .{ char, curW, curH });
                },
            }
            //map.SetTile(curW, curH, thisTile);
            //[curH][curW] = thisTile;
        }
        if (curW < w) std.debug.print("Info: {d} has fewer rows than expected e{d} > f{d}\n", .{ curH, w, curW });
        if (curW > w) std.debug.panic("Row: {d} did not match width expectations e{d} != f{d}\n", .{ curH, w, curW });
        curH += 1;
    }
    if (curH != h) std.debug.panic("We did not find the expected number of rows: e{d} != f{d}\n", .{ h, curH });
    return map;
}
