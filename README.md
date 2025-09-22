# 🎓 Student Records Database Management System (Optimized)

This project defines an optimized **Student Records DBMS** schema for **MySQL 8+**, designed with **normalization, constraints, indexing, and advanced features** to handle a full academic records system.  

The schema covers **students, instructors, departments, courses, classrooms, semesters, enrollments, assignments, and grades**. It also includes **views, indexes, sample data, and stored procedures** for efficient querying and management.

---

## 📂 File
- `student_records_schema_optimized.sql` → Full schema with sample data, views, and procedures.

---

## 🚀 Features
- **Normalized design (3NF/BCNF)** for efficient storage and consistency.
- **Comprehensive constraints**: primary keys, foreign keys, unique, check constraints.
- **Performance tuning**: indexes on frequently queried columns.
- **Business rules enforcement**:
  - Enrollment year validation.
  - Non-overlapping semesters.
  - Positive salaries and classroom capacities.
  - Course prerequisites with no self-dependency.
- **Relationships**:
  - 1:1 → Student ↔ Student Profile  
  - 1:N → Department ↔ Students, Department ↔ Instructors  
  - M:N → Student ↔ Section (via Enrollment)  
  - M:N (self) → Course ↔ Course (prerequisites)
- **Views**:
  - `student_department_view`: student + department info.  
  - `course_section_view`: courses, sections, instructors, and room details.
- **Stored Procedures**:
  - `GetStudentEnrollments(student_id)` → Shows a student’s enrollment history.  
  - `GetSectionEnrollments(section_id)` → Lists students in a given section.

---

## 🛠️ Installation

1. Ensure you have **MySQL 8+** installed and running.
2. Open the MySQL CLI:
   ```bash
   mysql -u root -p
