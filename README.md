# Pathlib

A filesystem path library for [Chapel](https://chapel-lang.org/).

Pathlib provides a `path` record that wraps common filesystem operations, offering a cleaner alternative to plain string manipulation with Chapel's `Path` and `FileSystem` modules.

## Installation

Add Pathlib as a Mason dependency:

```bash
mason add Pathlib@0.1.0
```

## Usage

```chapel
use Pathlib;

var p: path = "/usr/local/bin";
writeln(p.name);         // "bin"
writeln(p.parent);       // "/usr/local"
writeln(p.isAbsolute()); // true

// Join paths with /
var full = p / "subdir" / "file.txt";
// "/usr/local/bin/subdir/file.txt"
```

## License

See [Mason.toml](Mason.toml).
