// Database schema - version 3
// Added columns to teachers: postName, dateOfBirth, placeOfBirth, address (v2)
// Added columns to students: postName, placeOfBirth, guardianFirstName, guardianLastName, guardianPhone (v3)
// Added unique index on enrollments(studentId) to enforce single class per student (v4)
// Added periodMonth column to payments table (v5)// Added feeType column to payments table (v6)

const int kDatabaseVersion = 6;

const String sqlCreateUsers = '''
  CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    fullName TEXT NOT NULL,
    role TEXT NOT NULL,
    isActive INTEGER DEFAULT 1,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
''';

const String sqlCreateStudents = '''
  CREATE TABLE IF NOT EXISTS students (
    id TEXT PRIMARY KEY,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    currentLevel TEXT NOT NULL,
    photoUrl TEXT,
    enrollmentDate TEXT NOT NULL,
    dateOfBirth TEXT,
    address TEXT,
    parentName TEXT,
    parentPhone TEXT,
    isActive INTEGER DEFAULT 1,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
''';

const String sqlCreateTeachers = '''
  CREATE TABLE IF NOT EXISTS teachers (
    id TEXT PRIMARY KEY,
    firstName TEXT NOT NULL,
    lastName TEXT NOT NULL,
    postName TEXT DEFAULT '',
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    specializations TEXT NOT NULL,
    biography TEXT,
    photoUrl TEXT,
    dateOfBirth TEXT,
    placeOfBirth TEXT,
    address TEXT,
    isActive INTEGER DEFAULT 1,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL
  )
''';

const String sqlCreateClasses = '''
  CREATE TABLE IF NOT EXISTS classes (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    level TEXT NOT NULL,
    teacherId TEXT NOT NULL,
    description TEXT,
    maxCapacity INTEGER NOT NULL,
    currentEnrollment INTEGER DEFAULT 0,
    schedule TEXT NOT NULL,
    location TEXT NOT NULL,
    isActive INTEGER DEFAULT 1,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (teacherId) REFERENCES teachers(id)
  )
''';

const String sqlCreateEnrollments = '''
  CREATE TABLE IF NOT EXISTS enrollments (
    id TEXT PRIMARY KEY,
    studentId TEXT NOT NULL,
    classId TEXT NOT NULL,
    enrollmentDate TEXT NOT NULL,
    completionDate TEXT,
    status TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (studentId) REFERENCES students(id),
    FOREIGN KEY (classId) REFERENCES classes(id)
  )
''';

const String sqlCreatePayments = '''
  CREATE TABLE IF NOT EXISTS payments (
    id TEXT PRIMARY KEY,
    studentId TEXT NOT NULL,
    periodMonth TEXT NOT NULL DEFAULT '',
    feeType TEXT NOT NULL DEFAULT 'monthly',
    amount REAL NOT NULL,
    status TEXT NOT NULL,
    paymentDate TEXT NOT NULL,
    paymentMethod TEXT,
    notes TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (studentId) REFERENCES students(id)
  )
''';

const String sqlCreateAttendance = '''
  CREATE TABLE IF NOT EXISTS attendance (
    id TEXT PRIMARY KEY,
    studentId TEXT NOT NULL,
    classId TEXT NOT NULL,
    attendanceDate TEXT NOT NULL,
    status TEXT NOT NULL,
    notes TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (studentId) REFERENCES students(id),
    FOREIGN KEY (classId) REFERENCES classes(id)
  )
''';

const String sqlCreateExams = '''
  CREATE TABLE IF NOT EXISTS exams (
    id TEXT PRIMARY KEY,
    classId TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    examDate TEXT NOT NULL,
    status TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (classId) REFERENCES classes(id)
  )
''';

const String sqlCreateResults = '''
  CREATE TABLE IF NOT EXISTS results (
    id TEXT PRIMARY KEY,
    studentId TEXT NOT NULL,
    examId TEXT NOT NULL,
    score REAL NOT NULL,
    grade TEXT,
    resultDate TEXT NOT NULL,
    notes TEXT,
    createdAt TEXT NOT NULL,
    updatedAt TEXT NOT NULL,
    FOREIGN KEY (studentId) REFERENCES students(id),
    FOREIGN KEY (examId) REFERENCES exams(id)
  )
''';

const List<String> databaseTables = [
  sqlCreateUsers,
  sqlCreateStudents,
  sqlCreateTeachers,
  sqlCreateClasses,
  sqlCreateEnrollments,
  sqlCreatePayments,
  sqlCreateAttendance,
  sqlCreateExams,
  sqlCreateResults,
];

const List<String> databaseIndexes = [
  'CREATE INDEX IF NOT EXISTS idx_enrollments_studentId ON enrollments(studentId)',
  'CREATE INDEX IF NOT EXISTS idx_enrollments_classId ON enrollments(classId)',
  'CREATE INDEX IF NOT EXISTS idx_payments_studentId ON payments(studentId)',
  'CREATE INDEX IF NOT EXISTS idx_attendance_studentId ON attendance(studentId)',
  'CREATE INDEX IF NOT EXISTS idx_attendance_classId ON attendance(classId)',
  'CREATE INDEX IF NOT EXISTS idx_results_studentId ON results(studentId)',
  'CREATE INDEX IF NOT EXISTS idx_results_examId ON results(examId)',
  'CREATE INDEX IF NOT EXISTS idx_classes_teacherId ON classes(teacherId)',
  'CREATE INDEX IF NOT EXISTS idx_students_email ON students(email)',
  'CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)',
];

/// SQL statements for migrating from version 1 to version 2.
const List<String> migrationV1toV2 = [
  "ALTER TABLE teachers ADD COLUMN postName TEXT DEFAULT ''",
  "ALTER TABLE teachers ADD COLUMN dateOfBirth TEXT",
  "ALTER TABLE teachers ADD COLUMN placeOfBirth TEXT",
  "ALTER TABLE teachers ADD COLUMN address TEXT",
  "ALTER TABLE teachers ADD COLUMN isActive INTEGER DEFAULT 1",
];

/// SQL statements for migrating from version 2 to version 3.
const List<String> migrationV2toV3 = [
  "ALTER TABLE students ADD COLUMN postName TEXT DEFAULT ''",
  "ALTER TABLE students ADD COLUMN placeOfBirth TEXT",
  "ALTER TABLE students ADD COLUMN guardianFirstName TEXT",
  "ALTER TABLE students ADD COLUMN guardianLastName TEXT",
  "ALTER TABLE students ADD COLUMN guardianPhone TEXT",
];

/// SQL statements for migrating from version 3 to version 4.
const List<String> migrationV3toV4 = [
  "CREATE UNIQUE INDEX IF NOT EXISTS idx_enrollment_student ON enrollments(studentId)",
];

/// SQL statements for migrating from version 4 to version 5.
const List<String> migrationV4toV5 = [
  "ALTER TABLE payments ADD COLUMN periodMonth TEXT NOT NULL DEFAULT ''",
];

/// SQL statements for migrating from version 5 to version 6.
const List<String> migrationV5toV6 = [
  "ALTER TABLE payments ADD COLUMN feeType TEXT NOT NULL DEFAULT 'monthly'",
];
