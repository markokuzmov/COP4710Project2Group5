-- Build script for Pj2_5 (SQL Server)
-- Creates schema Bellini, tables, constraints, sample data.
-- Replace database name if desired.

IF DB_ID('Pj2_5') IS NOT NULL
BEGIN
    DROP DATABASE Pj2_5;
END
GO

CREATE DATABASE [Pj2_5];
GO

USE [Pj2_5];
GO

-- Create schema
CREATE SCHEMA Bellini AUTHORIZATION dbo;
GO

--------------------------------------------------------------------------------
-- Tables (normalized - Bellini schema)
--------------------------------------------------------------------------------

-- Majors offered
CREATE TABLE Bellini.Major (
    major_code    CHAR(5)       NOT NULL PRIMARY KEY, -- e.g., 'BSCS'
    name          NVARCHAR(100) NOT NULL,
    total_req_hours INT         NOT NULL CHECK (total_req_hours > 0),
    description   NVARCHAR(400) NULL
);

-- Catalog courses (course definitions)
CREATE TABLE Bellini.Course (
    course_id     CHAR(10)      NOT NULL PRIMARY KEY, -- e.g., 'CIS4622'
    title         NVARCHAR(200) NOT NULL,
    credits       DECIMAL(3,1)  NOT NULL CHECK (credits > 0),
    level         INT            NOT NULL CHECK (level >= 0),
    description   NVARCHAR(2000) NULL,
    is_state_mandated BIT       NOT NULL DEFAULT(0)
);

-- Prerequisites and corequisites
CREATE TABLE Bellini.CoursePrerequisite (
    course_id     CHAR(10) NOT NULL,
    prereq_id     CHAR(10) NOT NULL,
    is_corequisite BIT NOT NULL DEFAULT(0),
    constraint PK_CoursePrereq PRIMARY KEY (course_id, prereq_id, is_corequisite),
    CONSTRAINT FK_CP_COURSE FOREIGN KEY (course_id) REFERENCES Bellini.Course(course_id),
    CONSTRAINT FK_CP_PREREQ FOREIGN KEY (prereq_id) REFERENCES Bellini.Course(course_id)
);

-- Maps which courses belong to which majors (required|elective)
CREATE TABLE Bellini.MajorCourse (
    major_code CHAR(5) NOT NULL,
    course_id  CHAR(10) NOT NULL,
    required_type   CHAR(10) NOT NULL CHECK (required_type IN ('CORE','ELECTIVE','MANDATED')),
    semester_recommended VARCHAR(20) NULL,
    PRIMARY KEY (major_code, course_id),
    CONSTRAINT FK_MC_MAJOR FOREIGN KEY (major_code) REFERENCES Bellini.Major(major_code),
    CONSTRAINT FK_MC_COURSE FOREIGN KEY (course_id) REFERENCES Bellini.Course(course_id)
);

-- Four-year study plan header (per major + catalog year)
CREATE TABLE Bellini.StudyPlan (
    studyplan_id INT IDENTITY(1,1) PRIMARY KEY,
    major_code   CHAR(5) NOT NULL,
    catalog_year VARCHAR(9) NOT NULL, -- e.g., '2022-2023'
    description  NVARCHAR(400) NULL,
    CONSTRAINT FK_SP_MAJOR FOREIGN KEY (major_code) REFERENCES Bellini.Major(major_code)
);

-- StudyPlan line items: courses by semester number (1..8)
CREATE TABLE Bellini.StudyPlanItem (
    studyplan_id INT NOT NULL,
    year_semester INT NOT NULL, -- 1..8 (1=FreshmanFall, 2=FreshmanSpring, ...)
    course_id CHAR(10) NOT NULL,
    PRIMARY KEY (studyplan_id, year_semester, course_id),
    CONSTRAINT FK_SPI_SP FOREIGN KEY (studyplan_id) REFERENCES Bellini.StudyPlan(studyplan_id),
    CONSTRAINT FK_SPI_COURSE FOREIGN KEY (course_id) REFERENCES Bellini.Course(course_id)
);

-- People: students and instructors (single person table)
CREATE TABLE Bellini.Person (
    person_id INT IDENTITY(1000,1) PRIMARY KEY,
    first_name NVARCHAR(80) NOT NULL,
    last_name  NVARCHAR(80) NOT NULL,
    email      NVARCHAR(150) UNIQUE,
    phone      NVARCHAR(30) NULL,
    address    NVARCHAR(250) NULL,
    is_student BIT NOT NULL DEFAULT(0),
    is_instructor BIT NOT NULL DEFAULT(0),
    hire_date DATE NULL,
    created_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

-- Students specific info
CREATE TABLE Bellini.Student (
    student_id INT PRIMARY KEY, -- same as person_id
    banner_id  CHAR(10) NOT NULL UNIQUE, -- e.g., 'S20250001'
    major_code CHAR(5) NOT NULL,
    admit_term VARCHAR(20) NOT NULL,
    classification VARCHAR(20) NULL, -- e.g., 'Freshman'
    attempted_hours INT NOT NULL DEFAULT(0),
    earned_hours INT NOT NULL DEFAULT(0),
    gpa DECIMAL(3,2) NULL CHECK (gpa BETWEEN 0 AND 4.0),
    FOREIGN KEY (student_id) REFERENCES Bellini.Person(person_id),
    FOREIGN KEY (major_code) REFERENCES Bellini.Major(major_code)
);

-- Stores historic major changes
CREATE TABLE Bellini.MajorChange (
    majorchange_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT NOT NULL,
    old_major CHAR(5) NOT NULL,
    new_major CHAR(5) NOT NULL,
    change_date DATE NOT NULL,
    change_term VARCHAR(20) NOT NULL,
    note NVARCHAR(400) NULL,
    CONSTRAINT FK_MC_STUDENT FOREIGN KEY (student_id) REFERENCES Bellini.Student(student_id),
    CONSTRAINT FK_MC_OLDMAJOR FOREIGN KEY (old_major) REFERENCES Bellini.Major(major_code),
    CONSTRAINT FK_MC_NEWMAJOR FOREIGN KEY (new_major) REFERENCES Bellini.Major(major_code)
);

-- Instructors (references Person)
CREATE TABLE Bellini.Instructor (
    instructor_id INT PRIMARY KEY, -- same as person_id
    office_location NVARCHAR(100) NULL,
    office_hours NVARCHAR(200) NULL,
    hire_rank NVARCHAR(50) NULL, -- e.g. 'Professor'
    FOREIGN KEY (instructor_id) REFERENCES Bellini.Person(person_id)
);

-- Semesters
CREATE TABLE Bellini.Semester (
    semester_id INT IDENTITY(1,1) PRIMARY KEY,
    year INT NOT NULL,
    term VARCHAR(20) NOT NULL, -- 'Fall','Spring','Summer'
    start_date DATE NULL,
    end_date DATE NULL,
    UNIQUE (year, term)
);

-- Physical locations / rooms
CREATE TABLE Bellini.Location (
    location_id INT IDENTITY(1,1) PRIMARY KEY,
    building NVARCHAR(100) NOT NULL,
    room NVARCHAR(30) NOT NULL,
    capacity INT NULL
);

-- Classes/sections (a specific offering of a course in a semester)
CREATE TABLE Bellini.Class (
    class_id INT IDENTITY(1,1) PRIMARY KEY,
    course_id CHAR(10) NOT NULL,
    semester_id INT NOT NULL,
    section VARCHAR(10) NOT NULL, -- '001','002'..
    crn INT NOT NULL,               -- unique per semester (see constraint)
    instructor_id INT NULL,         -- FK to person/instructor
    ta_student_id INT NULL,         -- student who is TA (nullable)
    type VARCHAR(30) NOT NULL DEFAULT('Lecture'), -- 'Lecture','Lab'
    total_capacity INT NOT NULL CHECK (total_capacity > 0),
    total_enrollment INT NOT NULL DEFAULT(0),
    status VARCHAR(20) NOT NULL DEFAULT('OPEN'), -- 'OPEN','CLOSED'
    notes NVARCHAR(400) NULL,
    CONSTRAINT FK_CLASS_COURSE FOREIGN KEY (course_id) REFERENCES Bellini.Course(course_id),
    CONSTRAINT FK_CLASS_SEM FOREIGN KEY (semester_id) REFERENCES Bellini.Semester(semester_id),
    CONSTRAINT FK_CLASS_INSTR FOREIGN KEY (instructor_id) REFERENCES Bellini.Person(person_id),
    CONSTRAINT FK_CLASS_TA FOREIGN KEY (ta_student_id) REFERENCES Bellini.Student(student_id),
    CONSTRAINT UQ_Class_CRN_Sem UNIQUE (crn, semester_id),
    CONSTRAINT UQ_Class_Course_Sec_Sem UNIQUE (course_id, section, semester_id)
);

-- Class meeting times (allows multiple meeting slots per class)
CREATE TABLE Bellini.ClassSchedule (
    schedule_id INT IDENTITY(1,1) PRIMARY KEY,
    class_id INT NOT NULL,
    day_of_week CHAR(3) NOT NULL CHECK (day_of_week IN ('Mon','Tue','Wed','Thu','Fri','Sat','Sun')),
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    location_id INT NULL,
    CONSTRAINT FK_CS_CLASS FOREIGN KEY (class_id) REFERENCES Bellini.Class(class_id),
    CONSTRAINT FK_CS_LOC FOREIGN KEY (location_id) REFERENCES Bellini.Location(location_id)
);

-- Enrollment records (registrations)
CREATE TABLE Bellini.Enrollment (
    enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
    class_id INT NOT NULL,
    student_id INT NOT NULL,
    enroll_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    status VARCHAR(20) NOT NULL DEFAULT('ENROLLED'), -- ENROLLED, DROPPED, WAITLISTED
    grade_letter VARCHAR(5) NULL, -- A, B+, etc. (for fall 2025 classes when grades are entered)
    grade_points DECIMAL(4,2) NULL, -- numeric points for grade (for GPA calc)
    attempts INT NOT NULL DEFAULT(0),
    CONSTRAINT FK_ENR_CLASS FOREIGN KEY (class_id) REFERENCES Bellini.Class(class_id),
    CONSTRAINT FK_ENR_STUD FOREIGN KEY (student_id) REFERENCES Bellini.Student(student_id),
    CONSTRAINT UQ_ENR_STUD_CLASS UNIQUE (class_id, student_id)
);

-- Grades by instructor (audit/history)
CREATE TABLE Bellini.GradeEntry (
    gradeentry_id INT IDENTITY(1,1) PRIMARY KEY,
    enrollment_id INT NOT NULL,
    entered_by INT NOT NULL, -- person_id (instructor)
    entry_date DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    grade_letter VARCHAR(5) NOT NULL,
    grade_points DECIMAL(4,2) NOT NULL,
    comment NVARCHAR(400) NULL,
    CONSTRAINT FK_GE_ENR FOREIGN KEY (enrollment_id) REFERENCES Bellini.Enrollment(enrollment_id),
    CONSTRAINT FK_GE_BY FOREIGN KEY (entered_by) REFERENCES Bellini.Person(person_id)
);

-- Simple view to see course offerings
GO
CREATE VIEW Bellini.vCourseOfferings AS
SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.semester_id,
    c.section,
    c.crn,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    c.type,
    p.first_name + ' ' + p.last_name AS instructor_name,
    ta.first_name + ' ' + ta.last_name AS ta_name
FROM Bellini.Class AS c
JOIN Bellini.Course AS co 
    ON c.course_id = co.course_id
LEFT JOIN Bellini.Person AS p 
    ON c.instructor_id = p.person_id
LEFT JOIN Bellini.Student s 
    ON c.ta_student_id = s.student_id
LEFT JOIN Bellini.Person ta
    ON s.student_id = ta.person_id;
GO
--------------------------------------------------------------------------------
-- Triggers (basic, maintain counts)
--------------------------------------------------------------------------------
-- Update Class.total_enrollment when enrollment inserted / deleted / status change

CREATE TRIGGER Bellini.trg_Enrollment_Insert
ON Bellini.Enrollment
AFTER INSERT
AS
BEGIN
    -- Only count real enrollments, not waitlist or dropped
    UPDATE c
    SET c.total_enrollment = c.total_enrollment + 1
    FROM Bellini.Class c
    JOIN inserted i ON c.class_id = i.class_id
    WHERE i.status = 'ENROLLED';
END;
GO

CREATE TRIGGER Bellini.trg_Enrollment_Delete
ON Bellini.Enrollment
AFTER DELETE
AS
BEGIN
    UPDATE c
    SET c.total_enrollment = c.total_enrollment - 1
    FROM Bellini.Class c
    JOIN deleted d ON c.class_id = d.class_id
    WHERE d.status = 'ENROLLED';
END;
GO

CREATE TRIGGER Bellini.trg_Enrollment_Update
ON Bellini.Enrollment
AFTER UPDATE
AS
BEGIN
    --------------------------------------------------------
    -- 1) Decrement count for rows that *were* ENROLLED but are no longer
    --------------------------------------------------------
    UPDATE c
    SET c.total_enrollment = c.total_enrollment - 1
    FROM Bellini.Class c
    JOIN deleted d ON c.class_id = d.class_id
    JOIN inserted i ON d.enrollment_id = i.enrollment_id
    WHERE d.status = 'ENROLLED'
      AND i.status <> 'ENROLLED';

    --------------------------------------------------------
    -- 2) Increment count for rows that *became* ENROLLED
    --------------------------------------------------------
    UPDATE c
    SET c.total_enrollment = c.total_enrollment + 1
    FROM Bellini.Class c
    JOIN deleted d ON c.class_id = d.class_id
    JOIN inserted i ON d.enrollment_id = i.enrollment_id
    WHERE d.status <> 'ENROLLED'
      AND i.status = 'ENROLLED';
END;
GO

--------------------------------------------------------------------------------
-- Sample data: majors, courses, study plans, semesters, people, students, major changes, classes, enrollments
--------------------------------------------------------------------------------

-- Majors
INSERT INTO Bellini.Major (major_code, name, total_req_hours, description)
VALUES
('BSCS','B.S. Computer Science',120,'Core CS curriculum'),
('BSCP','B.S. Computer Programming',120,'Programming-focused curriculum'),
('BSIT','B.S. Information Technology',120,'IT and systems'),
('BSCyS','B.S. Cybersecurity',120,'Security-focused curriculum');

-- Courses (a small set)
INSERT INTO Bellini.Course (course_id, title, credits, level, description, is_state_mandated)
VALUES
('CIS1101','Intro to Computing',3.0,1000,'Introduction to computing and programming basics',0),
('CIS1202','Programming I',3.0,1000,'Procedural programming fundamentals',0),
('CIS2103','Data Structures',3.0,2000,'Lists, trees, graphs and their algorithms',0),
('CIS2201','Computer Architecture',3.0,2000,'CPU, memory, I/O',0),
('CIS3105','Operating Systems',3.0,3000,'Processes, threads, scheduling',0),
('CIS3207','Database Systems',3.0,3000,'Relational databases, SQL',0),
('CIS4301','Software Engineering',3.0,4000,'Software process and design',0),
('MAC2104','Calculus I',4.0,2000,'Calculus for engineers and CS students',0),
('STA2001','Intro Statistics',3.0,2000,'Statistics basics',0),
('SEC3001','Intro to Cybersecurity',3.0,3000,'Security fundamentals',1);

-- Course prerequisites (example)
INSERT INTO Bellini.CoursePrerequisite (course_id, prereq_id, is_corequisite)
VALUES
('CIS2103','CIS1202',0),
('CIS3105','CIS2103',0),
('CIS3207','CIS2103',0),
('CIS4301','CIS3207',0),
('SEC3001','CIS2103',0);

-- MajorCourse linking (required/core/elective)
INSERT INTO Bellini.MajorCourse (major_code, course_id, required_type)
VALUES
('BSCS','CIS1101','CORE'),
('BSCS','CIS1202','CORE'),
('BSCS','CIS2103','CORE'),
('BSCS','CIS3207','CORE'),
('BSCS','CIS4301','CORE'),
('BSCS','MAC2104','CORE'),
('BSCS','STA2001','ELECTIVE'),
('BSCyS','SEC3001','MANDATED'),
('BSIT','CIS1202','CORE'),
('BSIT','CIS2201','CORE');

-- Study plans (one plan per major for sample catalog year)
INSERT INTO Bellini.StudyPlan (major_code, catalog_year, description)
VALUES
('BSCS','2022-2023','BSCS four-year plan sample'),
('BSIT','2022-2023','BSIT four-year plan sample'),
('BSCP','2022-2023','BSCP four-year plan sample'),
('BSCyS','2022-2023','BSCyS four-year plan sample');

-- Add study plan items (simplified)
-- For BSCS studyplan_id = 1 (since identity)
INSERT INTO Bellini.StudyPlanItem (studyplan_id, year_semester, course_id)
VALUES
(1,1,'CIS1101'),
(1,1,'CIS1202'),
(1,2,'MAC2104'),
(1,3,'CIS2103'),
(1,4,'CIS2201'),
(1,5,'CIS3207'),
(1,6,'STA2001'),
(1,7,'CIS4301');

-- Semesters: Fall 2025 and Spring 2026
INSERT INTO Bellini.Semester (year, term, start_date, end_date)
VALUES
(2025,'Fall','2025-08-20','2025-12-19'),
(2026,'Spring','2026-01-12','2026-05-08');

-- Locations
INSERT INTO Bellini.Location (building, room, capacity)
VALUES
('Bellini Hall','101',60),
('Bellini Hall','102',40),
('Engineering Building','201',80);

-- People: instructors and students (person table)
-- Instructors
INSERT INTO Bellini.Person (first_name, last_name, email, phone, is_instructor, hire_date)
VALUES
('Alice','Nguyen','anguyen@bellini.edu','555-1001',1,'2015-08-01'),
('Robert','Smith','rsmith@bellini.edu','555-1002',1,'2018-09-01'),
('Karen','Lopez','klopez@bellini.edu','555-1003',1,'2020-01-15');

-- Capture inserted person ids for instructors
-- (assuming identity started at 1000)
-- Students (20+)
INSERT INTO Bellini.Person (first_name, last_name, email, phone, is_student)
VALUES
('Marko','Kuzmov','mkuzmov@student.bellini.edu','555-2001',1),
('Jacob','Lopez','jlopez@student.bellini.edu','555-2002',1),
('Anthony','Reed','areed@student.bellini.edu','555-2003',1),
('Jordan','Parker','jparker@student.bellini.edu','555-2004',1),
('Emily','Chen','echen@student.bellini.edu','555-2005',1),
('Sam','O''Neill','sonnell@student.bellini.edu','555-2006',1),
('Priya','Singh','psingh@student.bellini.edu','555-2007',1),
('Liam','Garcia','lgarcia@student.bellini.edu','555-2008',1),
('Sophia','Wang','swang@student.bellini.edu','555-2009',1),
('Ethan','Brown','ebrown@student.bellini.edu','555-2010',1),
('Olivia','Martinez','omartinez@student.bellini.edu','555-2011',1),
('Noah','Kim','nkim@student.bellini.edu','555-2012',1),
('Ava','Davis','adavis@student.bellini.edu','555-2013',1),
('Mason','Lopez','mlopez@student.bellini.edu','555-2014',1),
('Isabella','Ng','ing@student.bellini.edu','555-2015',1),
('Lucas','Young','lyoung@student.bellini.edu','555-2016',1),
('Mia','Hernandez','mhernandez@student.bellini.edu','555-2017',1),
('James','Wright','jwright@student.bellini.edu','555-2018',1),
('Charlotte','Hill','chill@student.bellini.edu','555-2019',1),
('Benjamin','Scott','bscott@student.bellini.edu','555-2020',1);

-- Insert Student rows referencing Person person_id values
-- We'll map person.person_id to banner_id and majors
-- For deterministic sample, query the Person rows to find ids; but here we will JOIN to insert.
-- Assign majors roughly balanced
INSERT INTO Bellini.Student (student_id, banner_id, major_code, admit_term, classification, attempted_hours, earned_hours, gpa)
SELECT person_id,
       'S' + RIGHT('2026' + CAST(ROW_NUMBER() OVER (ORDER BY person_id) AS VARCHAR(6)),6) AS banner_id,
       CASE WHEN rn % 4 = 1 THEN 'BSCS' WHEN rn % 4 = 2 THEN 'BSIT' WHEN rn % 4 = 3 THEN 'BSCP' ELSE 'BSCyS' END AS major_code,
       'Fall 2024' AS admit_term,
       'Sophomore' AS classification,
       30 AS attempted_hours,
       30 AS earned_hours,
       3.20 AS gpa
FROM (
    SELECT person_id, ROW_NUMBER() OVER (ORDER BY person_id) rn
    FROM Bellini.Person
    WHERE is_student = 1
) s;
-- Now ensure at least 20 students inserted (we created 20 names above)

-- Major changes: pick three students to change majors
-- find three student ids
WITH three AS (
    SELECT s.student_id
    FROM Bellini.Student AS s
    ORDER BY s.student_id
    OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY
)
INSERT INTO Bellini.MajorChange (
    student_id, old_major, new_major, change_date, change_term, note
)
SELECT 
    s.student_id,
    s.major_code,
    CASE s.major_code 
        WHEN 'BSCS' THEN 'BSIT'
        WHEN 'BSIT' THEN 'BSCyS'
        ELSE 'BSCS'
    END AS new_major,
    '2025-11-01',
    'Fall 2025',
    'Sample major change'
FROM three t
JOIN Bellini.Student s ON t.student_id = s.student_id;


-- Update those students' current major to new_major
UPDATE s
SET major_code =
    CASE s.major_code WHEN 'BSCS' THEN 'BSIT' WHEN 'BSIT' THEN 'BSCyS' ELSE 'BSCS' END
FROM Bellini.Student s
WHERE s.student_id IN (SELECT student_id FROM Bellini.MajorChange);

-- Create instructors rows in Instructor table (map the Person ids who are instructors)
INSERT INTO Bellini.Instructor (instructor_id, office_location, office_hours)
SELECT person_id, 'Bellini Hall 502', 'Mon 2-4pm, Wed 10-12pm'
FROM Bellini.Person WHERE is_instructor = 1;

-- Create a couple of classes for Fall 2025 (semester_id = 1)
-- Provide CRNs unique within semester (e.g., 92001..92010)
INSERT INTO Bellini.Class (course_id, semester_id, section, crn, instructor_id, ta_student_id, type, total_capacity, status)
VALUES
('CIS1202', 1, '001', 92001, (SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1), NULL, 'Lecture', 50, 'OPEN'),
('CIS2103', 1, '001', 92002, (SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1), NULL, 'Lecture', 40, 'OPEN'),
('CIS3207', 1, '001', 92003, (SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1 ORDER BY person_id DESC), NULL, 'Lecture', 35, 'OPEN'),
('CIS4301', 1, '001', 92004, (SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1 ORDER BY person_id), NULL, 'Lecture', 30, 'OPEN');

-- Assign two students as TAs for a Fall 2025 class
-- Pick two student_ids
DECLARE @ta1 INT = (SELECT TOP 1 student_id FROM Bellini.Student);
DECLARE @ta2 INT = (SELECT TOP 1 student_id FROM Bellini.Student WHERE student_id > @ta1);

-- Update Class to assign TAs for the CIS2103 class (crn 92002)
UPDATE Bellini.Class
SET ta_student_id = @ta1
WHERE crn = 92002 AND semester_id = 1;

-- Add another section and assign second TA
INSERT INTO Bellini.Class (course_id, semester_id, section, crn, instructor_id, ta_student_id, type, total_capacity, status)
VALUES
('CIS2103',1,'002',92005,(SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1), @ta2, 'Lecture', 30, 'OPEN');

-- Add ClassSchedule for some classes
INSERT INTO Bellini.ClassSchedule (class_id, day_of_week, start_time, end_time, location_id)
SELECT class_id, 'Mon', '09:00', '10:15', 1 FROM Bellini.Class WHERE crn IN (92001,92002);
INSERT INTO Bellini.ClassSchedule (class_id, day_of_week, start_time, end_time, location_id)
SELECT class_id, 'Wed', '09:00', '10:15', 1 FROM Bellini.Class WHERE crn IN (92001,92002);

-- Add sample Spring 2026 classes (semester_id = 2)
INSERT INTO Bellini.Class (course_id, semester_id, section, crn, instructor_id, type, total_capacity, status)
VALUES
('CIS2103',2,'001',93001,(SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1), 'Lecture', 40, 'OPEN'),
('CIS3207',2,'001',93002,(SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1 ORDER BY person_id DESC),'Lecture',35,'OPEN');

-- Enroll a few students into Fall 2025 classes (so TA class has at least one student)
-- enroll student @ta1 into crn 92002 (CIS2103.001)
DECLARE @classid_cis2103_001 INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92002 AND semester_id = 1);
DECLARE @stud1 INT = (SELECT TOP 1 student_id FROM Bellini.Student ORDER BY student_id);
DECLARE @stud2 INT = (SELECT TOP 1 student_id FROM Bellini.Student ORDER BY student_id DESC);

INSERT INTO Bellini.Enrollment (class_id, student_id, status)
VALUES
(@classid_cis2103_001, @stud1, 'ENROLLED'),
(@classid_cis2103_001, @stud2, 'ENROLLED');

-- enroll other students into CIS1202 (crn 92001)
DECLARE @classid_cis1202 INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92001 AND semester_id = 1);
INSERT INTO Bellini.Enrollment (class_id, student_id, status)
SELECT @classid_cis1202, student_id, 'ENROLLED' FROM (SELECT TOP 5 student_id FROM Bellini.Student ORDER BY student_id) s;

-- Simulate that Fall 2025 grades have been entered for one class (CIS2103.001)
-- Create grade entries for those two enrolled students
INSERT INTO Bellini.GradeEntry (enrollment_id, entered_by, grade_letter, grade_points, comment)
SELECT e.enrollment_id, (SELECT TOP 1 person_id FROM Bellini.Person WHERE is_instructor=1), 'A', 4.0, 'Final grade'
FROM Bellini.Enrollment e
WHERE e.class_id = @classid_cis2103_001;

-- Simple updates to students attempted/earned hours (can be computed later but we set some values)
UPDATE Bellini.Student
SET attempted_hours = 45, earned_hours = 45, gpa = 3.35
WHERE student_id IN (SELECT student_id FROM Bellini.Student);
