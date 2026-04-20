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

proc testIsSymlinkTrue(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var target = testTempDir:path / "_pathlib_test_symlink_target";
  target.touch();
  var link = testTempDir:path / "_pathlib_test_symlink_link";
  FileSystem.symlink(target.toStr(), link.toStr());
  test.assertTrue(link.isSymlink());
}

proc testIsSymlinkFalse(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "_pathlib_test_not_symlink";
  p.touch();
  test.assertFalse(p.isSymlink());
}

proc testCopyFile(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var src = testTempDir:path / "_pathlib_test_copy_src.txt";
  src.touch();
  // Write some content to verify the copy
  {
    use IO;
    var f = IO.open(src.toStr(), ioMode.cw);
    var w = f.writer(locking=false);
    w.write("copy content");
    w.close();
    f.close();
  }
  var dest = testTempDir:path / "_pathlib_test_copy_dest.txt";
  src.copy(dest);
  test.assertTrue(dest.exists());
  test.assertTrue(dest.isFile());
  // Verify content was copied
  {
    use IO;
    var f = IO.open(dest.toStr(), ioMode.r);
    var r = f.reader(locking=false);
    var content: string;
    r.readAll(content);
    r.close();
    f.close();
    test.assertEqual(content, "copy content");
  }
}

proc testCopyDir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var src = testTempDir:path / "_pathlib_test_copy_dir_src";
  src.mkdir();
  (src / "child.txt").touch();
  var dest = testTempDir:path / "_pathlib_test_copy_dir_dest";
  src.copy(dest);
  test.assertTrue(dest.exists());
  test.assertTrue(dest.isDir());
  test.assertTrue((dest / "child.txt").exists());
}

proc testCopyNonexistent(test: borrowed Test) throws {
  var src = testTempDir:path / "_pathlib_test_copy_nonexistent";
  var dest = testTempDir:path / "_pathlib_test_copy_nonexistent_dest";
  try {
    src.copy(dest);
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}

proc testMoveFile(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var src = testTempDir:path / "_pathlib_test_move_src.txt";
  src.touch();
  {
    use IO;
    var f = IO.open(src.toStr(), ioMode.cw);
    var w = f.writer(locking=false);
    w.write("move content");
    w.close();
    f.close();
  }
  var dest = testTempDir:path / "_pathlib_test_move_dest.txt";
  src.move(dest);
  test.assertFalse(src.exists());
  test.assertTrue(dest.exists());
  test.assertTrue(dest.isFile());
  // Verify content was moved
  {
    use IO;
    var f = IO.open(dest.toStr(), ioMode.r);
    var r = f.reader(locking=false);
    var content: string;
    r.readAll(content);
    r.close();
    f.close();
    test.assertEqual(content, "move content");
  }
}

proc testMoveDir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var src = testTempDir:path / "_pathlib_test_move_dir_src";
  src.mkdir();
  (src / "child.txt").touch();
  var dest = testTempDir:path / "_pathlib_test_move_dir_dest";
  src.move(dest);
  test.assertFalse(src.exists());
  test.assertTrue(dest.exists());
  test.assertTrue(dest.isDir());
  test.assertTrue((dest / "child.txt").exists());
}

proc testMoveNonexistent(test: borrowed Test) throws {
  var src = testTempDir:path / "_pathlib_test_move_nonexistent";
  var dest = testTempDir:path / "_pathlib_test_move_nonexistent_dest";
  try {
    src.move(dest);
    test.assertTrue(false);
  } catch {
    test.assertTrue(true);
  }
}

proc testFindFiles(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_findfiles";
  dir.mkdir();
  (dir / "a.txt").touch();
  (dir / "b.txt").touch();
  var count = 0;
  for f in dir.findFiles() {
    test.assertTrue(f.exists());
    count += 1;
  }
  test.assertEqual(count, 2);
}

proc testFindFilesRecursive(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_findfiles_recursive";
  dir.mkdir();
  (dir / "a.txt").touch();
  (dir / "sub").mkdir();
  (dir / "sub" / "b.txt").touch();
  var count = 0;
  for f in dir.findFiles(recursive=true) {
    test.assertTrue(f.exists());
    count += 1;
  }
  test.assertEqual(count, 2);
}

proc testListDir(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_listdir";
  dir.mkdir();
  (dir / "file1.txt").touch();
  (dir / "file2.txt").touch();
  (dir / "subdir").mkdir();
  var count = 0;
  for entry in dir.listDir() {
    count += 1;
  }
  test.assertEqual(count, 3);
}

proc testListDirFilesOnly(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_listdir_files";
  dir.mkdir();
  (dir / "file1.txt").touch();
  (dir / "file2.txt").touch();
  (dir / "subdir").mkdir();
  var count = 0;
  for entry in dir.listDir(dirs=false) {
    count += 1;
  }
  test.assertEqual(count, 2);
}

proc testWalkDirs(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_walkdirs";
  dir.mkdir();
  (dir / "sub1").mkdir();
  (dir / "sub1" / "sub2").mkdir();
  var count = 0;
  for d in dir.walkDirs(sort=true) {
    count += 1;
  }
  // Should find dir, dir/sub1, dir/sub1/sub2
  test.assertEqual(count, 3);
}

proc testWalkDirsDepth(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var dir = testTempDir:path / "_pathlib_test_walkdirs_depth";
  dir.mkdir();
  (dir / "sub1").mkdir();
  (dir / "sub1" / "sub2").mkdir();
  var count = 0;
  for d in dir.walkDirs(depth=1, sort=true) {
    count += 1;
  }
  // depth=1: dir and dir/sub1 only
  test.assertEqual(count, 2);
}

UnitTest.main();
