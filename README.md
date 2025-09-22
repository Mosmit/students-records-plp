# 🎓 Student Records Database (MySQL)

## 📌 Project Overview
This project implements a **full-featured relational database** for managing student records in a university/college setting.  
It is designed in **MySQL 8+** with normalization, proper constraints, and clear relationships between entities.  

The database covers departments, students, instructors, courses, semesters, classrooms, enrollment, grading, and assignments — providing a foundation for a complete **Student Information System (SIS)**.

---

## 🗂️ Database Details
- **Database Name:** `student_records_db`  
- **Engine:** InnoDB  
- **Character Set:** `utf8mb4`  
- **Collation:** `utf8mb4_0900_ai_ci`  

---

## 📊 Schema Overview
### Entities
- **Department** – academic units with code, budget, head instructor.  
- **Student** – personal info, enrollment year, department.  
- **Student Profile** – extended details (address, contacts, emergency info).  
- **Instructor** – teaching staff with title, salary, department.  
- **Semester** – academic terms (Fall 2025, etc.).  
- **Course** – offered courses, credits, prerequisites.  
- **Course Prerequisite** – many-to-many self-referencing relation.  
- **Classroom** – teaching rooms with facilities and capacity.  
- **Section** – offerings of courses in specific semesters.  
- **Grade** – grading scale (A–F, W).  
- **Enrollment** – many-to-many between students and course sections.  
- **Assignment** – tasks within a section.  
- **Assignment Submission** – student submissions for assignments.  

---

## 🔗 Relationships
- **1:1** – `student ↔ student_profile`  
- **1:M** – `department → student`, `course → section`, `instructor → section`  
- **M:N** – `student ↔ section` (via `enrollment`)  
- **M:N (self-referential)** – `course ↔ prerequisite_course`  

---

## ⚙️ Features & Constraints
- **PRIMARY KEYS** on all tables.  
- **FOREIGN KEYS** with `CASCADE`, `SET NULL`, `RESTRICT` actions.  
- **UNIQUE constraints** (e.g., `student.email`, `course.course_code`).  
- **CHECK constraints** (e.g., valid enrollment year, positive salary, course credits).  
- **ENUM types** for controlled values (student status, section type, instructor title).  
- **Indexes** for faster queries.  
- **Views** for common queries:
  - `student_department_view`
  - `course_section_view`  
- **Stored Procedures**:
  - `GetStudentEnrollments(student_id)`
  - `GetSectionEnrollments(section_id)`  
- **Sample Data** inserted into `grade` table.  

---

## 🚀 How to Use
1. Ensure **MySQL 8+** is installed.  
2. Run the SQL script:  
   ```bash
   mysql -u root -p < student_records_schema_optimized.sql
