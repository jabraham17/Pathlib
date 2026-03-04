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
module Pathlib {
  import Path;
  import FileSystem as FS;

  class PathError: Error {
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
  record path {
    @chpldoc.nodoc
    var pathStr: string;

    /* Initialize a ``path`` from a string representing a filesystem path. */
    proc init(pathStr: string) {
      this.pathStr = pathStr;
    }

    /* Copy-initialize a ``path`` from another ``path``. */
    proc init=(other: path) {
      this.pathStr = other.pathStr;
    }
    operator =(ref x: path, other: path) do
      x.pathStr = other.pathStr;

    /* Implicitly initialize a ``path`` from a ``string``. */
    proc init=(other: string) {
      this.pathStr = other;
    }
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

    /*
      Return ``true`` if this path refers to an existing file or directory.
    */
    proc exists(): bool throws {
      return FS.exists(this.pathStr);
    }

    /*
      Return ``true`` if this path points to a regular file.
    */
    proc isFile(): bool throws {
      return FS.isFile(this.pathStr);
    }

    /*
      Return ``true`` if this path points to a directory.
    */
    proc isDir(): bool throws {
      return FS.isDir(this.pathStr);
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
      if isDir(this.pathStr) {
        if existOk {
          return;
        } else {
          throw new PathError("Directory already exists");
        }
        mkdir(this.pathStr, parents=parents);
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


}
