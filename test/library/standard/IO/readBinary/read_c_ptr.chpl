use IO;
use CTypes;

readCptrTest(openReader("./c_ptr_input/cptr8.bin", locking=false), 8);
readCptrTest(openReader("./c_ptr_input/cptr16.bin", locking=false), 16);
readCptrTest(openReader("./c_ptr_input/cptr32.bin", locking=false), 32);
readCptrTest(openReader("./c_ptr_input/cptr64.bin", locking=false), 64);

// read 0..9 from the given file, expecting the given integer size,
//  and ensure that the correct values were read
proc readCptrTest(reader, param isize: int) {
    var cm = allocate(uint(isize), 10);
    var num_read = reader.readBinary(cm, 10 * (isize / 8));
    var correct = true;
    for i in (0:uint(8))..<10 do correct &= cm[i] == i;
    writeln(num_read, "\t", correct);
    deallocate(cm);
}


readCptrTestTooMany(openReader("./c_ptr_input/cptr8.bin", locking=false), 8);
readCptrTestTooMany(openReader("./c_ptr_input/cptr16.bin", locking=false), 16);
readCptrTestTooMany(openReader("./c_ptr_input/cptr32.bin", locking=false), 32);
readCptrTestTooMany(openReader("./c_ptr_input/cptr64.bin", locking=false), 64);

// try expecting a larger number of values than are present in the file.
//  ensure that the first 10 values were read correctly, and that 'num_read' is correct
proc readCptrTestTooMany(reader, param isize: int) {
    var cm = allocate(uint(isize), 12);
    var num_read = reader.readBinary(cm, 12 * (isize / 8) + 1);
    var correct = true;
    for i in (0:uint(8))..<10 do correct &= cm[i] == i;
    writeln(num_read, "\t", correct);
    deallocate(cm);
}
