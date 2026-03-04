use UnitTest;
use Pathlib;

proc testJoinTwoPaths(test: borrowed Test) throws {
  var result = path.join("/home", "user");
  test.assertEqual(result.toStr(), "/home/user");
}

proc testJoinMultiple(test: borrowed Test) throws {
  var result = path.join("/home", "user", "documents");
  test.assertEqual(result.toStr(), "/home/user/documents");
}

proc testJoinWithPathArgs(test: borrowed Test) throws {
  var a: path = "/home";
  var b: path = "user";
  var result = path.join(a, b);
  test.assertEqual(result.toStr(), "/home/user");
}

proc testPlusPathPath(test: borrowed Test) throws {
  var a: path = "/home";
  var b: path = "user";
  var result = a / b;
  test.assertEqual(result.toStr(), "/home/user");
}

proc testPlusStringPath(test: borrowed Test) throws {
  var b: path = "user";
  var result = "/home" / b;
  test.assertEqual(result.toStr(), "/home/user");
}

proc testPlusPathString(test: borrowed Test) throws {
  var a: path = "/home";
  var result = a / "user";
  test.assertEqual(result.toStr(), "/home/user");
}

proc testPlusChained(test: borrowed Test) throws {
  var p: path = "/home";
  var full = p / "user" / "documents" / "file.txt";
  test.assertEqual(full.toStr(), "/home/user/documents/file.txt");
}

proc testPlusEqualsPath(test: borrowed Test) throws {
  var p: path = "/home";
  var rhs: path = "user";
  p /= rhs;
  test.assertEqual(p.toStr(), "/home/user");
}

proc testPlusEqualsString(test: borrowed Test) throws {
  var p: path = "/home";
  p /= "user";
  test.assertEqual(p.toStr(), "/home/user");
}

UnitTest.main();
