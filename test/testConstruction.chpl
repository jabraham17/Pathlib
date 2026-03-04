use UnitTest;
use Pathlib;

proc testInitFromString(test: borrowed Test) throws {
  var p = new path("/usr/local/bin");
  test.assertEqual(p.toStr(), "/usr/local/bin");
}

proc testCopyInit(test: borrowed Test) throws {
  var p1 = new path("/tmp/foo");
  var p2: path = p1;
  test.assertEqual(p2.toStr(), "/tmp/foo");
}

proc testInitFromStringImplicit(test: borrowed Test) throws {
  var p: path = "/usr/local";
  test.assertEqual(p.toStr(), "/usr/local");
}

proc testCastStringToPath(test: borrowed Test) throws {
  var p = "/home/user":path;
  test.assertEqual(p.toStr(), "/home/user");
}

proc testCastPathToString(test: borrowed Test) throws {
  var p = new path("/home/user");
  var s = p:string;
  test.assertEqual(s, "/home/user");
}

proc testToStr(test: borrowed Test) throws {
  var p = new path("/a/b/c");
  test.assertEqual(p.toStr(), "/a/b/c");
}

UnitTest.main();
