use UnitTest;
use Pathlib;
use Pathlib.IOHelpers;
use IO;
use FileSystem;
use JSON;

config const testTempDir = "/tmp/pathlib_test_iohelpers";

@chplcheck.ignore("UnusedFormal")
proc createTempDir(test: borrowed Test) throws {
  if FileSystem.exists(testTempDir) {
    FileSystem.rmTree(testTempDir);
  }
  FileSystem.mkdir(testTempDir);
}

proc testOpenWrite(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "open_write.txt";
  var f = open(p, ioMode.cw);
  {
    var w = f.writer(locking=false);
    w.write("hello");
  }
  f.close();
  test.assertTrue(p.exists());
  test.assertTrue(p.isFile());
}

proc testOpenReadBack(test: borrowed Test) throws {
  test.dependsOn(testOpenWrite);
  var p = testTempDir:path / "open_write.txt";
  var f = open(p, ioMode.r);
  var r = f.reader(locking=false);
  var content: string;
  r.readAll(content);
  f.close();
  test.assertEqual(content, "hello");
}

proc testOpenReader(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "openreader_test.txt";
  // Create the file first
  {
    var f = open(p, ioMode.cw);
    var w = f.writer(locking=false);
    w.write("reader content");
  }
  var r = openReader(p, locking=false);
  var content: string;
  r.readAll(content);
  test.assertEqual(content, "reader content");
}

proc testOpenWriter(test: borrowed Test) throws {
  test.dependsOn(createTempDir);
  var p = testTempDir:path / "openwriter_test.txt";
  var w = openWriter(p, locking=false);
  w.write("writer content");
  w.close();

  // Read back and verify
  var r = openReader(p, locking=false);
  var content: string;
  r.readAll(content);
  test.assertEqual(content, "writer content");
}

record TestRecord {
  var x: int;
  var y: string;
}

proc testOpenReaderWriterWithJsonSerializer(test: borrowed Test) throws {
  test.dependsOn(createTempDir);

  var p = testTempDir:path / "json_test.json";
  var w = openWriter(p, locking=false, serializer=new jsonSerializer());
  var rec = new TestRecord(42, "hello");
  w.write(rec);
  w.close();

  var r = openReader(p, locking=false, deserializer=new jsonDeserializer());
  var rec2: TestRecord;
  r.read(rec2);
  test.assertEqual(rec2.x, 42);
  test.assertEqual(rec2.y, "hello");

}

UnitTest.main();

