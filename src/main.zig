//
//
//
//
//
//    I. qpEngine
//                                                         ,,
//                      `7MM"""YMM                         db
//                        MM    `7
//      ,dW"Yvd`7MMpdMAo. MM   d    `7MMpMMMb.  .P"Ybmmm `7MM  `7MMpMMMb.  .gP"Ya
//     ,W'   MM  MM   `Wb MMmmMM      MM    MM :MI  I8     MM    MM    MM ,M'   Yb
//     8M    MM  MM    M8 MM   Y  ,   MM    MM  WmmmP"     MM    MM    MM 8M""""""
//     YA.   MM  MM   ,AP MM     ,M   MM    MM 8M          MM    MM    MM YM.    ,
//      'MbmdMM  MMbmmd'.JMMmmmmMMM .JMML  JMML.YMMMMMb  .JMML..JMML  JMML.`Mbmmd'
//           MM  MM                            6'     dP
//         .JMMLJMML.                          YbmmmdY'
//
//    II. Copyright (c) 2025-present Rocco Ruscitti
//
//    III. License
//    This software is not yet licensed and is not available for use or distribution.
//
//
//
//
//

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() != .leak);
    const allocator = gpa.allocator();

    var regex = try Regex.from("a(b|c)d", true, allocator);
    defer regex.deinit();

    std.debug.print("regex pattern: {s}\n", .{regex.getPattern().?});

    const subject = "abd acd";
    var matches: std.ArrayList(RegexMatch) = regex.searchAll(subject, 0, -1);
    defer regex.deinitMatchList(&matches);

    try tests.expectEqual(2, matches.items.len);

    try tests.expect(std.mem.eql(u8, "abd", matches.items[0].getStringAt(0)));
    try tests.expectEqual(0, matches.items[0].getStartAt(0));
    try tests.expectEqual(3, matches.items[0].getEndAt(0));

    try tests.expect(std.mem.eql(u8, "b", matches.items[0].getStringAt(1)));
    try tests.expectEqual(1, matches.items[0].getStartAt(1));
    try tests.expectEqual(2, matches.items[0].getEndAt(1));

    try tests.expect(std.mem.eql(u8, "acd", matches.items[1].getStringAt(0)));
    try tests.expectEqual(4, matches.items[1].getStartAt(0));
    try tests.expectEqual(7, matches.items[1].getEndAt(0));

    try tests.expect(std.mem.eql(u8, "c", matches.items[1].getStringAt(1)));
    try tests.expectEqual(5, matches.items[1].getStartAt(1));
    try tests.expectEqual(6, matches.items[1].getEndAt(1));

    std.debug.print("Hello, qpEngine!\n", .{});
}

const std = @import("std");
const qp = @import("qp");

const Allocator = std.mem.Allocator;
const Regex = qp.util.Regex;
const RegexMatch = qp.util.RegexMatch;
const tests = std.testing;
