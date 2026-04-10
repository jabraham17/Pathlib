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

proc testIsFileTrue(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_isfile";
  p.touch();
  test.assertTrue(p.isFile());
}

proc testIsFileFalseDir(test: borrowed Test) throws {
  var p: path = "/tmp";
  test.assertFalse(p.isFile());
}

proc testIsFileFalseNotExist(test: borrowed Test) throws {
  var p: path = "/nonexistent_path_that_should_not_exist_abc123";
  test.assertFalse(p.isFile());
}

proc testRemoveFile(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_remove_file";
  p.touch();
  test.assertTrue(p.exists());
  p.remove();
  test.assertFalse(p.exists());
}

proc testRemoveDir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_remove_dir";
  p.mkdir();
  test.assertTrue(p.isDir());
  p.remove();
  test.assertFalse(p.exists());
}

proc testRemoveDirRecursive(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_remove_recursive";
  (p / "child").mkdir(parents=true);
  (p / "child" / "file.txt").touch();
  test.assertTrue(p.exists());
  p.remove();
  test.assertFalse(p.exists());
}

proc testRemoveNonexistent(test: borrowed Test) throws {
  var p: path = testTempDir:path / "_pathlib_test_remove_nonexistent";
  try {
    p.remove();
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}

proc testCwd(test: borrowed Test) throws {
  var p = path.cwd();
  test.assertTrue(p.isAbsolute());
  test.assertTrue(p.exists());
}

proc testChdir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var original = path.cwd();
  var target: path = testTempDir;
  target.chdir();
  var current = path.cwd();
  // Resolve both to handle symlinks (e.g. /tmp -> /private/tmp on macOS)
  test.assertEqual(current.resolve():string, target.resolve():string);
  original.chdir();
}

proc testChdirContext(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var original = path.cwd();
  var target: path = testTempDir;
  manage target.pushChdir() {
    var inside = path.cwd();
    test.assertEqual(inside.resolve():string, target.resolve():string);
  }
  var after = path.cwd();
  test.assertEqual(after.resolve():string, original.resolve():string);
}

proc testChdirDoesNotExist(test: borrowed Test) throws {
  var target = testTempDir:path / "_pathlib_test_chdir_nonexistent";
  try {
    target.chdir();
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}
proc testChdirNotADir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var target = testTempDir:path / "_pathlib_test_chdir_notadir";
  target.touch();
  try {
    target.chdir();
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}
proc testChdirContextDoesNotExist(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var target = testTempDir:path / "_pathlib_test_chdir_context_nonexistent";
  try {
    manage target.pushChdir() {
      var inside = path.cwd();
      test.assertEqual(inside.resolve():string, target.resolve():string);
    }
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}

proc testResolve(test: borrowed Test) throws {
  var p: path = "/tmp";
  var resolved = p.resolve();
  // /tmp may resolve to /private/tmp on macOS
  test.assertTrue(resolved.isAbsolute());
}

UnitTest.main();
