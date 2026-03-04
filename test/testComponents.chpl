use UnitTest;
use Pathlib;
use List;

proc testName(test: borrowed Test) throws {
  var p: path = "/usr/local/bin";
  test.assertEqual(p.name, "bin");
}

proc testNameWithFile(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  test.assertEqual(p.name, "readme.txt");
}

proc testNameSingleComponent(test: borrowed Test) throws {
  var p: path = "file.txt";
  test.assertEqual(p.name, "file.txt");
}

proc testParent(test: borrowed Test) throws {
  var p: path = "/usr/local/bin";
  test.assertEqual(p.parent:string, "/usr/local");
}

proc testParentTrailingSlash(test: borrowed Test) throws {
  var p: path = "/usr/local/";
  test.assertEqual(p.parent:string, "/usr");
}

proc testParentDotDot(test: borrowed Test) throws {
  var p: path = "/usr/local/..";
  test.assertEqual(p.parent:string, "/usr/local");
}

proc testParentRoot(test: borrowed Test) throws {
  var p: path = "/";
  test.assertEqual(p.parent:string, "/");
}

proc testStem(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  test.assertEqual(p.stem, "readme");
}

proc testStemMultipleDots(test: borrowed Test) throws {
  var p: path = "/home/user/readme.tar.gz";
  test.assertEqual(p.stem, "readme.tar");
}

proc testStemNoExtension(test: borrowed Test) throws {
  var p: path = "/home/user/Makefile";
  test.assertEqual(p.stem, "Makefile");
}

proc testSuffix(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  test.assertEqual(p.suffix, ".txt");
}

proc testSuffixMultipleDots(test: borrowed Test) throws {
  var p: path = "/home/user/readme.tar.gz";
  test.assertEqual(p.suffix, ".gz");
}

proc testSuffixNone(test: borrowed Test) throws {
  var p: path = "/home/user/Makefile";
  test.assertEqual(p.suffix, "");
}

proc testParts(test: borrowed Test) throws {
  var p: path = "/usr/local/bin";
  var arr: list(string);
  for part in p.parts() do
    arr.pushBack(part);
  test.assertEqual(arr.size, 3);
  test.assertEqual(arr[0], "usr");
  test.assertEqual(arr[1], "local");
  test.assertEqual(arr[2], "bin");
}

proc testPartsRelative(test: borrowed Test) throws {
  var p: path = "a/b/c";
  var arr: list(string);
  for part in p.parts() do
    arr.pushBack(part);
  test.assertEqual(arr.size, 3);
  test.assertEqual(arr[0], "a");
  test.assertEqual(arr[1], "b");
  test.assertEqual(arr[2], "c");
}

UnitTest.main();
