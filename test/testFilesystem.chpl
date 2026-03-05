use UnitTest;
use Pathlib;
use FileSystem;

config const testTempDir = "/tmp/pathlib_test_temp_dir";

@chplcheck.ignore("UnusedFormal")
proc createTempDir(test: borrowed Test) throws {
  if FileSystem.exists(testTempDir) {
    FileSystem.rmTree(testTempDir);
  }
  FileSystem.mkdir(testTempDir);
}

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
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_touch_file";
  test.assertFalse(p.exists());
  test.assertFalse(p.isFile());
  p.touch();
  test.assertTrue(p.exists());
  test.assertTrue(p.isFile());
}

proc testMkdir(test: borrowed Test) throws {
  var p = testTempDir:path / "_pathlib_test_mkdir";
  test.assertFalse(p.exists());
  test.assertFalse(p.isDir());
  p.mkdir();
  test.assertTrue(p.exists());
  test.assertTrue(p.isDir());
}

proc testMkdirParents(test: borrowed Test) throws {
  var p = testTempDir:path / "_pathlib_test_mkdir_parents/child/grandchild";
  test.assertFalse(p.exists());
  test.assertFalse(p.isDir());
  p.mkdir(parents=true);
  test.assertTrue(p.exists());
  test.assertTrue(p.isDir());
}

proc testMkdirParentsAlreadyExists(test: borrowed Test) throws {
  var p =
    testTempDir:path / "_pathlib_test_mkdir_parents_exists/child/grandchild";
  test.assertFalse(p.exists());
  test.assertFalse(p.isDir());
  p.mkdir(parents=true);

  try {
    p.mkdir(parents=true);
    test.assertFalse(true);
  } catch {
    test.assertTrue(true);
  }

  // Try creating the same path again with parents=true,
  // should not throw an error
  try! p.mkdir(parents=true, existOk=true);

  test.assertTrue(p.exists());
  test.assertTrue(p.isDir());
}

proc testResolve(test: borrowed Test) throws {
  var p: path = "/tmp";
  var resolved = p.resolve();
  // /tmp may resolve to /private/tmp on macOS
  test.assertTrue(resolved.isAbsolute());
}

UnitTest.main();
