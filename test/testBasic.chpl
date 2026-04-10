use UnitTest;
use Pathlib;
use IO;

proc testSerialize(test: borrowed Test) throws {
  var p = new path("/usr/local/bin");
  var f = openMemFile();
  {
    var w = f.writer(locking=false);
    w.write(p);
  }
  var content: string;
  {
    var r = f.reader(locking=false);
    r.readAll(content);
  }
  test.assertEqual(content, "path(/usr/local/bin)");
}

UnitTest.main();
