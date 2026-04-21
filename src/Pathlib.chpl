/*
  Pathlib: An object-oriented filesystem path library for Chapel.

  Provides a ``path`` record that serves as a wrapper around many common
  filesystem path operations. This library has the advantage over plain string
  manipulation using :mod:`Path` and :mod:`FileSystem` in a few ways.

  * Provides more intuitive path operations like ``myPath / "subdir`` vs
    ``Path.joinPath(myPath, "subdir")``.

  * Helps developers write code that is more clear and semantically meaningful
    by using a dedicated ``path`` type instead of overloading string operations.

  Usage:

   .. literalinclude:: test/docExamples/basic.chpl
    :language: chapel
    :start-after: START_EXAMPLE
    :end-before: STOP_EXAMPLE
*/
@chpldoc.noUsage
@chpldoc.noAutoInclude
module Pathlib {
  import Path;
  import FileSystem as FS;
  import FileSystem.{cwd,chdir};

  /**/
  class PathError: Error {
    /**/
    proc init(msg: string) {
      super.init(msg);
    }
  }

  private proc removeSuffix(s: string, suffix: string): string {
    if s.endsWith(suffix) then
      return s[0..#(s.size - suffix.size)];
    else
      return s;
  }

  @chpldoc.nodoc
  record chdirManager: contextManager {
    var loc: locale;
    var targetDir: path;
    var originalDir: path;

    proc init(targetDir: path, loc: locale) throws {
      this.targetDir = targetDir;
      init this;
      this.originalDir = path.cwd(loc=loc);
      checkTargetDir();
    }
    @chpldoc.nodoc
    proc checkTargetDir() throws {
      if !this.targetDir.isDir() then
        throw new PathError("Target path is not a directory");
    }

    // TODO: this try! is so unfortunate but without it enterContext can't
    // implement the interface
    proc ref enterContext() do try! this.targetDir.chdir(loc=loc);
    proc ref exitContext(in err: owned Error?) throws {
      if err then throw err;
      this.originalDir.chdir(loc=loc);
    }
  }

  /*
    A filesystem path. Supports path joining, component access,
    existence checks, and basic filesystem mutations.

    A ``path`` can be constructed from a ``string`` and freely converted
    back.

    .. literalinclude:: test/docExamples/join.chpl
      :language: chapel
      :start-after: START_EXAMPLE
      :end-before: STOP_EXAMPLE
  */
  record path: writeSerializable {
    @chpldoc.nodoc
    var pathStr: string;

    /* Initialize a ``path`` from a string representing a filesystem path. */
    proc init(pathStr: string) {
      this.pathStr = pathStr;
    }
    @chpldoc.nodoc
    proc init() {
      this.pathStr = "";
    }

    /* Copy-initialize a ``path`` from another ``path``. */
    proc init=(other: path) {
      this.pathStr = other.pathStr;
    }
    /**/
    operator =(ref x: path, other: path) do
      x.pathStr = other.pathStr;

    /* Implicitly initialize a ``path`` from a ``string``. */
    proc init=(other: string) {
      this.pathStr = other;
    }
    /**/
    operator =(ref x: path, other: string) do
      x.pathStr = other;

    /* Allow casting from ``string`` to ``path``. */
    operator :(other: string, type t) where t == path do
      return new path(other);

    /* Return the string representation of this path. */
    proc toStr() do return this.pathStr;

    /* Get the string representation of this path. */
    operator :(other: path, type t) where t == string do
      return other.toStr();

    @chpldoc.nodoc
    proc serialize(writer, ref serializer) throws {
      writer.write("path(", this.pathStr, ")");
    }

    /*
      Join one or more path segments, inserting the platform separator
      between components. Accepts ``path`` or ``string`` arguments.
    */
    proc type join(args...?n): path {
      var s: n*string;
      for param i in 0..<n {
        if args[i].type == path {
          s[i] = (args[i]:string);
        } else if args[i].type == string {
          s[i] = args[i];
        } else {
          compilerError("join only accepts path or string arguments");
        }
      }
      return Path.joinPath((...s)):path;
    }

    /* Return a new ``path`` representing the current working directory. */
    proc type cwd(loc = here): path throws {
      return new path(loc.cwd());
    }

    /* Change the current working directory to this path. */
    proc chdir(loc = here) throws {
      loc.chdir(this.pathStr);
    }
    /*
      Returns a contextManager that will enter the given directory and return
      to the original directory when the context is exited. For example:

      .. code-block:: chapel

        var p = new path("/some/dir");
        manage p.pushChdir(p) {
          // CWD is now "/some/dir"
          ...
        }
        // CWD is restored to its original value
    */
    proc pushChdir(loc = here): chdirManager throws {
      return new chdirManager(this, loc);
    }

    /*
      Return ``true`` if this path refers to an existing file or directory.
    */
    proc exists(): bool {
      try {
        return FS.exists(this.pathStr);
      } catch {
        return false;
      }
    }

    /*
      Return ``true`` if this path points to a regular file.
    */
    proc isFile(): bool {
      try {
        return FS.isFile(this.pathStr);
      } catch {
        return false;
      }
    }

    /*
      Return ``true`` if this path points to a directory.
    */
    proc isDir(): bool {
      try {
        return FS.isDir(this.pathStr);
      } catch {
        return false;
      }
    }

    /*
      Return ``true`` if this path points to a symbolic link.
    */
    proc isSymlink(): bool {
      try {
        return FS.isSymlink(this.pathStr);
      } catch {
        return false;
      }
    }

    /*
      Create the file at this path if it does not exist, or update its
      modification time if it does. Analogous to the UNIX ``touch``
      command.

      :throws: If the file cannot be opened or created.
    */
    proc touch() throws {
      use IO;
      var f = open(this.pathStr, ioMode.cw);
      f.close();
    }

    /*
      Create the directory at this path.

      :arg parents: If ``true``, create missing parent directories as
                    needed (like ``mkdir -p``).
      :arg existOk: If ``true``, do not raise an error when the
                    directory already exists.

      :throws PathError: If the directory already exists and *existOk*
                         is ``false``.
    */
    proc mkdir(parents=false, existOk=false) throws {
      if this.isDir() {
        if existOk {
          return;
        } else {
          throw new PathError("Directory already exists");
        }
      } else {
        FS.mkdir(this.pathStr, parents=parents);
      }
    }

    /*
      Remove the file or directory at this path. If this path is a
      directory, it and all its contents are removed.

      :throws PathError: If the path does not exist.
    */
    proc remove() throws {
      if this.isDir() {
        FS.rmTree(this.pathStr);
      } else if this.isFile() {
        FS.remove(this.pathStr);
      } else {
        throw new PathError("Path does not exist");
      }
    }

    /*
      Copy the file or directory at this path to the destination path.

      See https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.copy
      and https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.copyTree
      for more details on the available options for copying files and directories.

    */
    proc copy(dest: path,
              copySymbolically: bool = false,
              metadata: bool = false,
              permissions: bool = true) throws {
      if this.isDir() {
        FS.copyTree(this.pathStr, dest.pathStr,
                    copySymbolically=copySymbolically,
                    metadata=metadata);
      } else if this.isFile() {
        FS.copy(this.pathStr, dest.pathStr,
                metadata=metadata,
                permissions=permissions);
      } else {
        throw new PathError("Path does not exist");
      }
    }

    /*
      Move the file or directory at this path to the destination path.

      See https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.moveDir
      for more details on moving directories.
    */
    proc move(dest: path) throws {
      if this.isDir() {
        FS.moveDir(this.pathStr, dest.pathStr);
      } else if this.isFile() {
        this.copy(dest, copySymbolically=false,
                  metadata=true, permissions=true);
        this.remove();
      } else {
        throw new PathError("Path does not exist");
      }
    }

    /*
      Yield the individual components of the path as strings.

      .. literalinclude:: test/docExamples/parts.chpl
        :language: chapel
        :start-after: START_EXAMPLE
        :end-before: STOP_EXAMPLE
    */
    iter parts(): string {
      const sep = Path.pathSep;
      for part in this.pathStr.split(sep) {
        if part != "" {
          yield part;
        }
      }
    }

    /*
      The logical parent of this path.

      .. literalinclude:: test/docExamples/parent.chpl
        :language: chapel
        :start-after: START_EXAMPLE
        :end-before: STOP_EXAMPLE
    */
    proc parent: path {

      if this.pathStr == Path.pathSep then
        return this; // The parent of root is root
      else if this.pathStr.endsWith(Path.pathSep) then
        return Path.dirname(removeSuffix(this.pathStr, Path.pathSep)):path;
      else
        return Path.dirname(this.pathStr):path;
    }

    /*
      The final component of this path (file or directory name).

      .. literalinclude:: test/docExamples/name.chpl
        :language: chapel
        :start-after: START_EXAMPLE
        :end-before: STOP_EXAMPLE
    */
    proc name: string {
      return Path.basename(this.pathStr);
    }

    /*
      The final component without its suffix (file extension).

      .. literalinclude:: test/docExamples/stem.chpl
        :language: chapel
        :start-after: START_EXAMPLE
        :end-before: STOP_EXAMPLE
    */
    proc stem: string {
      return Path.splitExt(this.name)[0];
    }

    /*
      The file extension of the final component, including the
      leading dot. Returns an empty string if there is no extension.

      .. literalinclude:: test/docExamples/suffix.chpl
        :language: chapel
        :start-after: START_EXAMPLE
        :end-before: STOP_EXAMPLE
    */
    proc suffix: string {
      return Path.splitExt(this.pathStr)[1];
    }

    /*
      Return a new path with the :proc:`name` changed to *newName*.
      The parent directory is preserved.

      :arg newName: The new filename (including any extension).
    */
    proc withName(newName: string): path {
      return this.parent / newName;
    }

    /*
      Return a new path with the :proc:`stem` changed to *newStem*.
      The parent directory and suffix are preserved.

      :arg newStem: The new stem (filename without extension).
    */
    proc withStem(newStem: string): path {
      var parent = this.parent;
      var suffix = this.suffix;
      return parent / (newStem + suffix);
    }

    /*
      Return a new path with the :proc:`suffix` changed to *newSuffix*.
      If *newSuffix* is empty, the current suffix is removed entirely.

      :arg newSuffix: The new extension, including the leading dot
                      (e.g. ``".txt"``). Pass ``""`` to remove the
                      suffix.
    */
    proc withSuffix(newSuffix: string): path {
      var parent = this.parent;
      var stem = this.stem;
      if newSuffix == "" then
        return parent / stem;
      else
        return parent / (stem + newSuffix);
    }


    /*
      Return ``true`` if this path is absolute (begins with ``/``).
    */
    proc isAbsolute(): bool {
      return Path.isAbsPath(this.pathStr);
    }

    /*
      Make the path absolute, resolving any symlinks and expanding
      environment variables. Returns a new ``path``.
    */
    proc resolve() throws {
      return Path.absPath(Path.realPath(Path.expandVars(this.pathStr))):path;
    }

    /*
      See https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.findFiles
    */
    iter findFiles(recursive: bool = false, hidden: bool = false): path throws {
      foreach entry in FS.findFiles(this.pathStr,
                                    recursive=recursive, hidden=hidden) {
        yield entry:path;
      }
    }
    @chpldoc.nodoc
    iter findFiles(
      recursive: bool = false, hidden: bool = false, param tag: iterKind
    ): path throws
    where tag == iterKind.standalone {
      forall entry in FS.findFiles(this.pathStr,
                                   recursive=recursive, hidden=hidden) {
        yield entry:path;
      }
    }

    /*
      See https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.listDir
    */
    iter listDir(
      hidden: bool = false, dirs: bool = true,
      files: bool = true, listlinks: bool = true
    ): path throws {
      foreach entry in FS.listDir(this.pathStr, hidden=hidden, dirs=dirs,
                                  files=files, listlinks=listlinks) {
        yield entry:path;
      }
    }

    /*
      See https://chapel-lang.org/docs/modules/standard/FileSystem.html#FileSystem.walkDirs
    */
    iter walkDirs(
      topdown: bool = true, depth: int = max(int),
      hidden: bool = false, followlinks: bool = false,
      sort: bool = false
    ): path throws {
      foreach entry in FS.walkDirs(this.pathStr, topdown=topdown, depth=depth,
                                   hidden=hidden, followlinks=followlinks,
                                   sort=sort) {
        yield entry:path;
      }
    }
    @chpldoc.nodoc
    iter walkDirs(
      topdown: bool = true, depth: int = max(int),
      hidden: bool = false, followlinks: bool = false,
      sort: bool = false, param tag: iterKind
    ): path throws
    where tag == iterKind.standalone {
      forall entry in FS.walkDirs(this.pathStr, topdown=topdown, depth=depth,
                                  hidden=hidden, followlinks=followlinks,
                                  sort=sort) {
        yield entry:path;
      }
    }

  }

  /* Join two ``path`` values. */
  operator /(lhs: path, rhs: path): path do
    return path.join(lhs, rhs);

  /* Join a ``string`` and a ``path``. */
  operator /(lhs: string, rhs: path): path do
    return path.join(lhs, rhs);

  /* Join a ``path`` and a ``string``. */
  operator /(lhs: path, rhs: string): path do
    return path.join(lhs, rhs);

  /* Append a ``path`` segment in place. */
  operator /=(ref lhs: path, rhs: path) do
    lhs = lhs / rhs;

  /* Append a ``string`` segment in place. */
  operator /=(ref lhs: path, rhs: string) do
    lhs = lhs / rhs;


  /*
    The ``Pathlib`` module provides a new abstraction for filesystem paths, but
    many parts of the standard library still require paths to be passed as
    arguments as strings. The ``IOHelpers`` module provides helper functions
    for working with the :mod:`IO` module that accept and return ``path``
    values instead of strings, allowing for easier interoperability between the
    two modules.

    To make use of this, simply include the module and use the helper functions
    when working with :mod:`IO`:

    .. literalinclude:: test/docExamples/ioHelpers.chpl
      :language: chapel
      :start-after: START_EXAMPLE
      :end-before: STOP_EXAMPLE
  */
  module IOHelpers {
    import IO;
    import Pathlib.path;

    /*
      See https://chapel-lang.org/docs/modules/standard/IO.html#IO.open
    */
    proc open(p:path, mode:IO.ioMode,
              hints=IO.ioHintSet.empty): IO.file throws do
      return IO.open(p:string, mode=mode, hints=hints);

    /*
      See https://chapel-lang.org/docs/modules/standard/IO.html#IO.openReader
    */
    proc openReader(p:path, param locking = false,
                    region: range(?) = 0.., hints=IO.ioHintSet.empty,
                    in deserializer: ?dt = none) throws {
      if dt == nothing then
        return IO.openReader(p:string, locking=locking, region=region,
                             hints=hints);
      else
        return IO.openReader(p:string, locking=locking, region=region,
                             hints=hints, deserializer=deserializer);
    }
    /*
      See https://chapel-lang.org/docs/modules/standard/IO.html#IO.openWriter
    */
    proc openWriter(p:path, param locking = false,
                    hints = IO.ioHintSet.empty,
                    in serializer: ?st = none) throws {
      if st == nothing then
        return IO.openWriter(p:string, locking=locking, hints=hints);
      else
        return IO.openWriter(p:string, locking=locking, hints=hints,
                             serializer=serializer);
    }
  }

}
