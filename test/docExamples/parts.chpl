use Pathlib;
use List;
// START_EXAMPLE
var p: path = "/usr/local/bin";
for part in p.parts() do
  writeln(part);
// "usr"
// "local"
// "bin"
// STOP_EXAMPLE
var partsArr: list(string);
for part in p.parts() do
  partsArr.pushBack(part);
assert(partsArr[0] == "usr");
assert(partsArr[1] == "local");
assert(partsArr[2] == "bin");
