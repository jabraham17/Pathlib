use Pathlib;
// START_EXAMPLE
var p1: path = "/usr/local/bin";
var p2: path = "/usr/local/";
var p3: path = "/usr/local/..";
writeln(p1.parent); // "/usr/local"
writeln(p2.parent); // "/usr"
writeln(p3.parent); // "/usr/local"
// STOP_EXAMPLE
assert(p1.parent:string == "/usr/local");
assert(p2.parent:string == "/usr");
assert(p3.parent:string == "/usr/local");
