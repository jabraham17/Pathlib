use UnitTest;
use Pathlib;

proc testWithName(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  var q = p.withName("notes.md");
  test.assertEqual(q.toStr(), "/home/user/notes.md");
}

proc testWithStem(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  var q = p.withStem("notes");
  test.assertEqual(q.toStr(), "/home/user/notes.txt");
}

proc testWithSuffix(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  var q = p.withSuffix(".md");
  test.assertEqual(q.toStr(), "/home/user/readme.md");
}

proc testWithSuffixRemove(test: borrowed Test) throws {
  var p: path = "/home/user/readme.txt";
  var q = p.withSuffix("");
  test.assertEqual(q.toStr(), "/home/user/readme");
}

UnitTest.main();
