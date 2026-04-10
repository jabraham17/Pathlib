// START_EXAMPLE
import Pathlib.path;
use Pathlib.IOHelpers;
use IO;

var p: path = "example.txt";
var f = open(p, ioMode.cw);
var w = f.writer();
w.write("Hello, world!");
w.close();
f.close();
// STOP_EXAMPLE

var f2 = open(p, ioMode.r);
var r = f2.reader(locking=false);
var content: string;
r.readAll(content);
f2.close();
assert(content == "Hello, world!");
p.remove();

