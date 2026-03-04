use Pathlib;
// START_EXAMPLE
var p: path = "/home/user";
var full = p / "documents" / "file.txt";
// full == "/home/user/documents/file.txt"
// STOP_EXAMPLE
assert(full:string == "/home/user/documents/file.txt");
