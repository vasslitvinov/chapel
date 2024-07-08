class Student { }
class BadStudent: Student { }
class GoodStudent: Student { }
class ExcellentStudent: Student { }

// This test works if acceptableStudentTypes is not a field,
// but gives a weird error if it is a field.
class AdvancedBasketWeaving {
  type acceptableStudentTypes =
    (borrowed GoodStudent, borrowed ExcellentStudent);
    // currently has to be concrete, see #10172

  proc accept(student: borrowed Student) {
    for param i in 0..acceptableStudentTypes.size-1 {
      if student: acceptableStudentTypes(i)? != nil {
        return "YES!";
      }
    }
    return "Computer says 'No'";
  }
}

var course = new owned AdvancedBasketWeaving();
writeln(course.accept(new owned Student()));
writeln(course.accept(new owned BadStudent()));
writeln(course.accept(new owned GoodStudent()));
writeln(course.accept(new owned ExcellentStudent()));
