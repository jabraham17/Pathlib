// START_EXAMPLE
use Pathlib;

var p: path = "/usr/local/bin";
writeln(p.name);         // "bin"
writeln(p.parent);       // "/usr/local"
writeln(p.isAbsolute()); // true
// STOP_EXAMPLE

assert(p.name == "bin");
assert(p.parent:string == "/usr/local");
assert(p.isAbsolute());
