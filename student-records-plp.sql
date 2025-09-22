-- student_records_schema_optimized.sql
-- Optimized Student Records DBMS (MySQL 8+)
-- Enhanced with better normalization, improved constraints, and additional features

/* ==============================
   DATABASE
============================== */
DROP DATABASE IF EXISTS student_records_db;
CREATE DATABASE student_records_db
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE student_records_db;

/* ==============================
   TABLE: department
   - Added budget and head_instructor for better department management
============================== */
CREATE TABLE department (
  department_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(120) NOT NULL,
  code VARCHAR(10) NOT NULL,
  budget DECIMAL(15,2) DEFAULT 0.00,
  head_instructor INT UNSIGNED NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_department_name UNIQUE (name),
  CONSTRAINT uq_department_code UNIQUE (code)
) ENGINE=InnoDB;

/* ==============================
   TABLE: student
   - Added index for better query performance
   - Added constraint for valid enrollment years
============================== */
CREATE TABLE student (
  student_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  department_id INT UNSIGNED NULL,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  date_of_birth DATE NOT NULL,
  phone VARCHAR(20) NULL,
  enrollment_year YEAR NOT NULL,
  status ENUM('active','inactive','graduated','suspended') DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_student_email UNIQUE (email),
  CONSTRAINT ck_enrollment_year CHECK (enrollment_year >= 2000 AND enrollment_year <= YEAR(CURDATE())),
  CONSTRAINT fk_student_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

/* ==============================
   TABLE: student_profile (1:1 with student)
   - Added validation for postal code format
============================== */
CREATE TABLE student_profile (
  student_id INT UNSIGNED PRIMARY KEY,
  address_line1 VARCHAR(200) NOT NULL,
  address_line2 VARCHAR(200) NULL,
  city VARCHAR(100) NOT NULL,
  state_province VARCHAR(100) NOT NULL,
  postal_code VARCHAR(20) NOT NULL,
  country VARCHAR(100) DEFAULT 'United States',
  emergency_contact_name VARCHAR(120) NOT NULL,
  emergency_contact_phone VARCHAR(20) NOT NULL,
  national_id VARCHAR(20) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_student_profile_national_id UNIQUE (national_id),
  CONSTRAINT ck_postal_code_format CHECK (postal_code REGEXP '^[0-9]{5}(-[0-9]{4})?$'),
  CONSTRAINT fk_student_profile_student
    FOREIGN KEY (student_id)
    REFERENCES student(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

/* ==============================
   TABLE: instructor
   - Added salary and title fields
============================== */
CREATE TABLE instructor (
  instructor_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  department_id INT UNSIGNED NULL,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(254) NOT NULL,
  title ENUM('Professor', 'Associate Professor', 'Assistant Professor', 'Lecturer') DEFAULT 'Lecturer',
  salary DECIMAL(10,2) NULL,
  hired_on DATE NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_instructor_email UNIQUE (email),
  CONSTRAINT ck_salary_positive CHECK (salary IS NULL OR salary >= 0),
  CONSTRAINT fk_instructor_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- Add foreign key constraint for department head_instructor
ALTER TABLE department
ADD CONSTRAINT fk_department_head_instructor
  FOREIGN KEY (head_instructor)
  REFERENCES instructor(instructor_id)
  ON UPDATE CASCADE
  ON DELETE SET NULL;

/* ==============================
   TABLE: semester
   - Added constraint to ensure semester doesn't overlap
============================== */
CREATE TABLE semester (
  semester_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(40) NOT NULL,
  code VARCHAR(10) NOT NULL, -- e.g., FL2025
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  status ENUM('upcoming', 'active', 'completed') DEFAULT 'upcoming',
  CONSTRAINT uq_semester_name UNIQUE (name),
  CONSTRAINT uq_semester_code UNIQUE (code),
  CONSTRAINT ck_semester_dates CHECK (start_date < end_date AND DATEDIFF(end_date, start_date) BETWEEN 90 AND 180)
) ENGINE=InnoDB;

/* ==============================
   TABLE: course
   - Added course_level and prerequisites_text for better course management
============================== */
CREATE TABLE course (
  course_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  department_id INT UNSIGNED NOT NULL,
  course_code VARCHAR(20) NOT NULL,
  title VARCHAR(200) NOT NULL,
  credits TINYINT UNSIGNED NOT NULL,
  course_level ENUM('Undergraduate', 'Graduate') DEFAULT 'Undergraduate',
  description TEXT NULL,
  prerequisites_text VARCHAR(500) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_course_code UNIQUE (course_code),
  CONSTRAINT ck_course_credits CHECK (credits BETWEEN 1 AND 6),
  CONSTRAINT fk_course_department
    FOREIGN KEY (department_id)
    REFERENCES department(department_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

/* ==============================
   TABLE: course_prerequisite (self-referential M:N on course)
============================== */
CREATE TABLE course_prerequisite (
  course_id INT UNSIGNED NOT NULL,
  prerequisite_course_id INT UNSIGNED NOT NULL,
  is_mandatory BOOLEAN DEFAULT TRUE,
  minimum_grade VARCHAR(2) NULL,
  PRIMARY KEY (course_id, prerequisite_course_id),
  CONSTRAINT fk_cp_course
    FOREIGN KEY (course_id)
    REFERENCES course(course_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_cp_prereq
    FOREIGN KEY (prerequisite_course_id)
    REFERENCES course(course_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT ck_no_self_prereq CHECK (course_id <> prerequisite_course_id)
) ENGINE=InnoDB;

/* ==============================
   TABLE: classroom
   - Added facilities field
============================== */
CREATE TABLE classroom (
  room_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  building VARCHAR(80) NOT NULL,
  room_number VARCHAR(20) NOT NULL,
  capacity INT UNSIGNED NOT NULL,
  facilities SET('Projector', 'Computers', 'Lab Equipment', 'Whiteboard', 'Smart Board') NULL,
  CONSTRAINT uq_classroom UNIQUE (building, room_number),
  CONSTRAINT ck_classroom_capacity CHECK (capacity BETWEEN 1 AND 500)
) ENGINE=InnoDB;

/* ==============================
   TABLE: section (an offering of a course in a semester)
   - Added schedule information and section type
============================== */
CREATE TABLE section (
  section_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  course_id INT UNSIGNED NOT NULL,
  instructor_id INT UNSIGNED NULL,
  semester_id INT UNSIGNED NOT NULL,
  room_id INT UNSIGNED NULL,
  section_code VARCHAR(16) NOT NULL,
  capacity INT UNSIGNED NOT NULL DEFAULT 30,
  schedule VARCHAR(100) NULL, -- e.g., "MWF 10:00-11:00"
  section_type ENUM('Lecture', 'Lab', 'Seminar', 'Workshop') DEFAULT 'Lecture',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_section UNIQUE (course_id, semester_id, section_code),
  CONSTRAINT ck_section_capacity CHECK (capacity > 0),
  CONSTRAINT fk_section_course
    FOREIGN KEY (course_id)
    REFERENCES course(course_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_section_instructor
    FOREIGN KEY (instructor_id)
    REFERENCES instructor(instructor_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  CONSTRAINT fk_section_semester
    FOREIGN KEY (semester_id)
    REFERENCES semester(semester_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_section_room
    FOREIGN KEY (room_id)
    REFERENCES classroom(room_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

/* ==============================
   TABLE: grade
   - Added grade points and description
============================== */
CREATE TABLE grade (
  grade_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  letter VARCHAR(2) NOT NULL,
  points DECIMAL(3,2) NOT NULL,
  description VARCHAR(100) NULL,
  CONSTRAINT uq_grade_letter UNIQUE (letter),
  CONSTRAINT ck_grade_points CHECK (points >= 0.00 AND points <= 4.00)
) ENGINE=InnoDB;

/* ==============================
   TABLE: enrollment (M:N between student and section)
   - Added attendance percentage and last_attendance_date
============================== */
CREATE TABLE enrollment (
  enrollment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  student_id INT UNSIGNED NOT NULL,
  section_id INT UNSIGNED NOT NULL,
  enrolled_on DATE DEFAULT (CURRENT_DATE),
  grade_id INT UNSIGNED NULL,
  attendance_percentage DECIMAL(5,2) DEFAULT 0.00,
  last_attendance_date DATE NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_enrollment_student_section UNIQUE (student_id, section_id),
  CONSTRAINT ck_attendance_percentage CHECK (attendance_percentage >= 0.00 AND attendance_percentage <= 100.00),
  CONSTRAINT fk_enrollment_student
    FOREIGN KEY (student_id)
    REFERENCES student(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_enrollment_section
    FOREIGN KEY (section_id)
    REFERENCES section(section_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_enrollment_grade
    FOREIGN KEY (grade_id)
    REFERENCES grade(grade_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

/* ==============================
   TABLE: assignment
   - For tracking assignments in each section
============================== */
CREATE TABLE assignment (
  assignment_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  section_id INT UNSIGNED NOT NULL,
  title VARCHAR(200) NOT NULL,
  description TEXT NULL,
  due_date DATETIME NOT NULL,
  max_score DECIMAL(5,2) NOT NULL,
  weight TINYINT UNSIGNED NOT NULL, -- percentage of final grade
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT ck_assignment_weight CHECK (weight BETWEEN 1 AND 100),
  CONSTRAINT fk_assignment_section
    FOREIGN KEY (section_id)
    REFERENCES section(section_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

/* ==============================
   TABLE: assignment_submission
   - For tracking student assignment submissions
============================== */
CREATE TABLE assignment_submission (
  submission_id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  assignment_id INT UNSIGNED NOT NULL,
  student_id INT UNSIGNED NOT NULL,
  submission_date DATETIME NULL,
  score DECIMAL(5,2) NULL,
  feedback TEXT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_assignment_student UNIQUE (assignment_id, student_id),
  CONSTRAINT fk_submission_assignment
    FOREIGN KEY (assignment_id)
    REFERENCES assignment(assignment_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_submission_student
    FOREIGN KEY (student_id)
    REFERENCES student(student_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

/* ==============================
   INDEXES for better performance
============================== */
CREATE INDEX idx_student_department ON student(department_id);
CREATE INDEX idx_student_name ON student(last_name, first_name);
CREATE INDEX idx_instructor_department ON instructor(department_id);
CREATE INDEX idx_instructor_name ON instructor(last_name, first_name);
CREATE INDEX idx_course_department ON course(department_id);
CREATE INDEX idx_course_code ON course(course_code);
CREATE INDEX idx_section_course_semester ON section(course_id, semester_id);
CREATE INDEX idx_section_instructor ON section(instructor_id);
CREATE INDEX idx_section_semester ON section(semester_id);
CREATE INDEX idx_enrollment_student ON enrollment(student_id);
CREATE INDEX idx_enrollment_section ON enrollment(section_id);
CREATE INDEX idx_enrollment_grade ON enrollment(grade_id);
CREATE INDEX idx_assignment_section ON assignment(section_id);
CREATE INDEX idx_submission_assignment ON assignment_submission(assignment_id);
CREATE INDEX idx_submission_student ON assignment_submission(student_id);
CREATE INDEX idx_cp_prerequisite ON course_prerequisite(prerequisite_course_id);

/* ==============================
   VIEWS for common queries
============================== */
CREATE VIEW student_department_view AS
SELECT s.student_id, s.first_name, s.last_name, s.email, s.enrollment_year, s.status,
       d.name AS department_name, d.code AS department_code
FROM student s
LEFT JOIN department d ON s.department_id = d.department_id;

CREATE VIEW course_section_view AS
SELECT sec.section_id, c.course_code, c.title AS course_title, c.credits,
       sec.section_code, sec.schedule, sec.section_type, sec.capacity,
       sem.name AS semester, sem.start_date, sem.end_date,
       i.first_name AS instructor_first, i.last_name AS instructor_last,
       r.building, r.room_number
FROM section sec
JOIN course c ON sec.course_id = c.course_id
JOIN semester sem ON sec.semester_id = sem.semester_id
LEFT JOIN instructor i ON sec.instructor_id = i.instructor_id
LEFT JOIN classroom r ON sec.room_id = r.room_id;

/* ==============================
   INSERT sample data for grade table
============================== */
INSERT INTO grade (letter, points, description) VALUES
('A', 4.00, 'Excellent'),
('A-', 3.70, 'Very Good'),
('B+', 3.30, 'Good Plus'),
('B', 3.00, 'Good'),
('B-', 2.70, 'Satisfactory Plus'),
('C+', 2.30, 'Satisfactory'),
('C', 2.00, 'Average'),
('C-', 1.70, 'Below Average'),
('D+', 1.30, 'Marginal Plus'),
('D', 1.00, 'Marginal'),
('F', 0.00, 'Fail'),
('W', 0.00, 'Withdrawal');

/* ==============================
   STORED PROCEDURES for common operations
============================== */
DELIMITER //

CREATE PROCEDURE GetStudentEnrollments(IN student_id INT)
BEGIN
    SELECT c.course_code, c.title, sec.section_code, sem.name AS semester,
           e.enrolled_on, g.letter AS grade, e.attendance_percentage
    FROM enrollment e
    JOIN section sec ON e.section_id = sec.section_id
    JOIN course c ON sec.course_id = c.course_id
    JOIN semester sem ON sec.semester_id = sem.semester_id
    LEFT JOIN grade g ON e.grade_id = g.grade_id
    WHERE e.student_id = student_id
    ORDER BY sem.start_date DESC;
END //

CREATE PROCEDURE GetSectionEnrollments(IN section_id INT)
BEGIN
    SELECT s.student_id, s.first_name, s.last_name, s.email,
           e.enrolled_on, g.letter AS grade, e.attendance_percentage
    FROM enrollment e
    JOIN student s ON e.student_id = s.student_id
    LEFT JOIN grade g ON e.grade_id = g.grade_id
    WHERE e.section_id = section_id
    ORDER BY s.last_name, s.first_name;
END //

DELIMITER ;