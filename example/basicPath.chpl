use Pathlib;

var p = new path("/usr") / "local" / "bin";
writeln(p.name);
writeln(p.parent);
writeln(p.isAbsolute());
