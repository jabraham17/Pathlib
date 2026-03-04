use UnitTest;
use Pathlib;
use FileSystem;

proc testIsAbsoluteTrue(test: borrowed Test) throws {
  var p: path = "/usr/local/bin";
  test.assertTrue(p.isAbsolute());
}

proc testIsAbsoluteFalse(test: borrowed Test) throws {
  var p: path = "relative/path";
  test.assertFalse(p.isAbsolute());
}

proc testExistsTrue(test: borrowed Test) throws {
  var p: path = "/tmp";
  test.assertTrue(p.exists());
}

proc testExistsFalse(test: borrowed Test) throws {
  var p: path = "/nonexistent_path_that_should_not_exist_abc123";
  test.assertFalse(p.exists());
}

proc testIsDirTrue(test: borrowed Test) throws {
  var p: path = "/tmp";
  test.assertTrue(p.isDir());
}

proc testIsDirFalse(test: borrowed Test) throws {
  var p: path = "/nonexistent_path_that_should_not_exist_abc123";
  test.assertFalse(p.isDir());
}

proc testTouch(test: borrowed Test) throws {
  var p: path = "/tmp/_pathlib_test_touch_file";
  p.touch();
  test.assertTrue(p.exists());
  test.assertTrue(p.isFile());
  // cleanup
  FileSystem.remove(p.toStr());
}

proc testResolve(test: borrowed Test) throws {
  var p: path = "/tmp";
  var resolved = p.resolve();
  // /tmp may resolve to /private/tmp on macOS
  test.assertTrue(resolved.isAbsolute());
}

UnitTest.main();
