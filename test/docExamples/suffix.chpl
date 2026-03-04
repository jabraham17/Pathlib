use Pathlib;
// START_EXAMPLE
var p: path = "/home/user/readme.txt";
writeln(p.suffix); // ".txt"
// STOP_EXAMPLE
assert(p.suffix == ".txt");
