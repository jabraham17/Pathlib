use Pathlib;
// START_EXAMPLE
var p: path = "/home/user/readme.tar.gz";
writeln(p.stem); // "readme.tar"
// STOP_EXAMPLE
assert(p.stem == "readme.tar");
