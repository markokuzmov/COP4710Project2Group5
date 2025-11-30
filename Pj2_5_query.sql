-- Query file for Pj2_5 (SQL Server)
-- Contains DML statements to support functional requirements 3.8.1 through 3.8.8
-- Each query is numbered and commented according to the requirement specification

USE [Pj2_5];
GO

--------------------------------------------------------------------------------
-- 3.8.1: View list of classes available for registration
-- Search by course prefix, course number, credit hours, or course level
-- Shows only classes that are not yet full and closed
--------------------------------------------------------------------------------

-- Search by course prefix (e.g., 'CIS')
-- Parameter: @CoursePrefix
DECLARE @CoursePrefix NVARCHAR(10) = 'CIS';

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.section,
    c.crn,
    c.type,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    s.year,
    s.term,
    CONCAT(p.first_name, ' ', p.last_name) AS instructor_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person p ON c.instructor_id = p.person_id
WHERE c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity
    AND co.course_id LIKE @CoursePrefix + '%'
ORDER BY co.course_id, c.section;

-- Search by course number (e.g., '2103')
-- Parameter: @CourseNumber
DECLARE @CourseNumber NVARCHAR(10) = '2103';

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.section,
    c.crn,
    c.type,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    s.year,
    s.term,
    CONCAT(p.first_name, ' ', p.last_name) AS instructor_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person p ON c.instructor_id = p.person_id
WHERE c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity
    AND co.course_id LIKE '%' + @CourseNumber
ORDER BY co.course_id, c.section;

-- Search by credit hours (e.g., 3.0)
-- Parameter: @CreditHours
DECLARE @CreditHours DECIMAL(3,1) = 3.0;

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.section,
    c.crn,
    c.type,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    s.year,
    s.term,
    CONCAT(p.first_name, ' ', p.last_name) AS instructor_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person p ON c.instructor_id = p.person_id
WHERE c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity
    AND co.credits = @CreditHours
ORDER BY co.course_id, c.section;

-- Search by course level (e.g., 2000, 4000)
-- Parameter: @CourseLevel
DECLARE @CourseLevel INT = 2000;

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.section,
    c.crn,
    c.type,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    s.year,
    s.term,
    CONCAT(p.first_name, ' ', p.last_name) AS instructor_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person p ON c.instructor_id = p.person_id
WHERE c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity
    AND co.level = @CourseLevel
ORDER BY co.course_id, c.section;

-- Combined search allowing multiple criteria
-- Parameters: @CoursePrefix, @CourseNumber, @CreditHours, @CourseLevel (all optional)
DECLARE @SearchPrefix NVARCHAR(10) = NULL; -- e.g., 'CIS' or NULL
DECLARE @SearchNumber NVARCHAR(10) = NULL; -- e.g., '2103' or NULL
DECLARE @SearchCredits DECIMAL(3,1) = NULL; -- e.g., 3.0 or NULL
DECLARE @SearchLevel INT = NULL; -- e.g., 2000 or NULL

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    c.section,
    c.crn,
    c.type,
    c.total_capacity,
    c.total_enrollment,
    c.status,
    s.year,
    s.term,
    CONCAT(p.first_name, ' ', p.last_name) AS instructor_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person p ON c.instructor_id = p.person_id
WHERE c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity
    AND (@SearchPrefix IS NULL OR co.course_id LIKE @SearchPrefix + '%')
    AND (@SearchNumber IS NULL OR co.course_id LIKE '%' + @SearchNumber)
    AND (@SearchCredits IS NULL OR co.credits = @SearchCredits)
    AND (@SearchLevel IS NULL OR co.level = @SearchLevel)
ORDER BY co.course_id, c.section;

--------------------------------------------------------------------------------
-- 3.8.2: View courses and total hours required by a major
--------------------------------------------------------------------------------

-- Parameter: @MajorCode
DECLARE @MajorCode CHAR(5) = 'BSCS';

SELECT 
    m.major_code,
    m.name AS major_name,
    m.total_req_hours,
    mc.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    mc.required_type,
    mc.semester_recommended
FROM Bellini.Major m
JOIN Bellini.MajorCourse mc ON m.major_code = mc.major_code
JOIN Bellini.Course co ON mc.course_id = co.course_id
WHERE m.major_code = @MajorCode
ORDER BY co.level, mc.required_type, co.course_id;

-- Summary: Total hours required by major
SELECT 
    m.major_code,
    m.name AS major_name,
    m.total_req_hours AS total_required_hours,
    COUNT(DISTINCT mc.course_id) AS total_courses,
    SUM(co.credits) AS sum_course_credits
FROM Bellini.Major m
JOIN Bellini.MajorCourse mc ON m.major_code = mc.major_code
JOIN Bellini.Course co ON mc.course_id = co.course_id
WHERE m.major_code = @MajorCode
GROUP BY m.major_code, m.name, m.total_req_hours;

--------------------------------------------------------------------------------
-- 3.8.3: View courses not yet registered but required by a major
-- Also show total hours needed to complete the degree
--------------------------------------------------------------------------------

-- Parameter: @StudentId
DECLARE @StudentId INT = 1003; -- example student_id

-- Step 1: Find courses required by student's major that are not yet taken
SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    mc.course_id,
    co.title AS course_title,
    co.credits,
    co.level,
    mc.required_type,
    mc.semester_recommended
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
JOIN Bellini.MajorCourse mc ON m.major_code = mc.major_code
JOIN Bellini.Course co ON mc.course_id = co.course_id
WHERE s.student_id = @StudentId
    AND mc.course_id NOT IN (
        -- Courses already taken (enrolled with passing grade or currently enrolled)
        SELECT DISTINCT cl.course_id
        FROM Bellini.Enrollment e
        JOIN Bellini.Class cl ON e.class_id = cl.class_id
        WHERE e.student_id = @StudentId
            AND e.status IN ('ENROLLED', 'COMPLETED')
    )
ORDER BY co.level, mc.required_type, co.course_id;

-- Step 2: Calculate total hours needed to complete the degree
SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    m.total_req_hours,
    s.earned_hours,
    (m.total_req_hours - s.earned_hours) AS hours_remaining,
    -- Calculate credits for courses not yet taken but required
    ISNULL(SUM(co.credits), 0) AS credits_from_remaining_required_courses
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
LEFT JOIN Bellini.MajorCourse mc ON m.major_code = mc.major_code
    AND mc.course_id NOT IN (
        SELECT DISTINCT cl.course_id
        FROM Bellini.Enrollment e
        JOIN Bellini.Class cl ON e.class_id = cl.class_id
        WHERE e.student_id = @StudentId
            AND e.status IN ('ENROLLED', 'COMPLETED')
    )
    LEFT JOIN Bellini.Course co ON mc.course_id = co.course_id
WHERE s.student_id = @StudentId
GROUP BY s.student_id, p.first_name, p.last_name, 
         s.major_code, m.name, m.total_req_hours, s.earned_hours;--------------------------------------------------------------------------------
-- 3.8.4: View four-year study plan, semester by semester
--------------------------------------------------------------------------------

-- Parameter: @MajorCode (or @StudyPlanId)
DECLARE @PlanMajorCode CHAR(5) = 'BSCS';

-- Get the study plan details with semester breakdown
SELECT 
    sp.studyplan_id,
    sp.major_code,
    m.name AS major_name,
    sp.catalog_year,
    spi.year_semester,
    CASE 
        WHEN spi.year_semester = 1 THEN 'Freshman Fall'
        WHEN spi.year_semester = 2 THEN 'Freshman Spring'
        WHEN spi.year_semester = 3 THEN 'Sophomore Fall'
        WHEN spi.year_semester = 4 THEN 'Sophomore Spring'
        WHEN spi.year_semester = 5 THEN 'Junior Fall'
        WHEN spi.year_semester = 6 THEN 'Junior Spring'
        WHEN spi.year_semester = 7 THEN 'Senior Fall'
        WHEN spi.year_semester = 8 THEN 'Senior Spring'
        ELSE 'Unknown'
    END AS semester_name,
    spi.course_id,
    co.title AS course_title,
    co.credits,
    co.level
FROM Bellini.StudyPlan sp
JOIN Bellini.Major m ON sp.major_code = m.major_code
JOIN Bellini.StudyPlanItem spi ON sp.studyplan_id = spi.studyplan_id
JOIN Bellini.Course co ON spi.course_id = co.course_id
WHERE sp.major_code = @PlanMajorCode
ORDER BY spi.year_semester, co.course_id;

-- Summary by semester showing total credits per semester
SELECT 
    sp.studyplan_id,
    sp.major_code,
    m.name AS major_name,
    sp.catalog_year,
    spi.year_semester,
    CASE 
        WHEN spi.year_semester = 1 THEN 'Freshman Fall'
        WHEN spi.year_semester = 2 THEN 'Freshman Spring'
        WHEN spi.year_semester = 3 THEN 'Sophomore Fall'
        WHEN spi.year_semester = 4 THEN 'Sophomore Spring'
        WHEN spi.year_semester = 5 THEN 'Junior Fall'
        WHEN spi.year_semester = 6 THEN 'Junior Spring'
        WHEN spi.year_semester = 7 THEN 'Senior Fall'
        WHEN spi.year_semester = 8 THEN 'Senior Spring'
        ELSE 'Unknown'
    END AS semester_name,
    COUNT(spi.course_id) AS course_count,
    SUM(co.credits) AS total_credits
FROM Bellini.StudyPlan sp
JOIN Bellini.Major m ON sp.major_code = m.major_code
JOIN Bellini.StudyPlanItem spi ON sp.studyplan_id = spi.studyplan_id
JOIN Bellini.Course co ON spi.course_id = co.course_id
WHERE sp.major_code = @PlanMajorCode
GROUP BY sp.studyplan_id, sp.major_code, m.name, sp.catalog_year, spi.year_semester
ORDER BY spi.year_semester;

--------------------------------------------------------------------------------
-- 3.8.5: View information of a specific course
-- Including credits, prerequisites, corequisites, and description
--------------------------------------------------------------------------------

-- Parameter: @CourseId
DECLARE @CourseId CHAR(10) = 'CIS2103';

-- Course basic information
SELECT 
    co.course_id,
    co.title,
    co.credits,
    co.level,
    co.description,
    co.is_state_mandated
FROM Bellini.Course co
WHERE co.course_id = @CourseId;

-- Prerequisites for the course
SELECT 
    cp.course_id,
    cp.prereq_id,
    co.title AS prerequisite_title,
    co.credits AS prerequisite_credits,
    'Prerequisite' AS requirement_type
FROM Bellini.CoursePrerequisite cp
JOIN Bellini.Course co ON cp.prereq_id = co.course_id
WHERE cp.course_id = @CourseId
    AND cp.is_corequisite = 0;

-- Corequisites for the course
SELECT 
    cp.course_id,
    cp.prereq_id AS coreq_id,
    co.title AS corequisite_title,
    co.credits AS corequisite_credits,
    'Corequisite' AS requirement_type
FROM Bellini.CoursePrerequisite cp
JOIN Bellini.Course co ON cp.prereq_id = co.course_id
WHERE cp.course_id = @CourseId
    AND cp.is_corequisite = 1;

-- Combined view: Course with all prerequisites and corequisites
SELECT 
    co.course_id,
    co.title,
    co.credits,
    co.level,
    co.description,
    co.is_state_mandated,
    cp.prereq_id,
    prereq_co.title AS prereq_title,
    CASE WHEN cp.is_corequisite = 1 THEN 'Corequisite' ELSE 'Prerequisite' END AS requirement_type
FROM Bellini.Course co
LEFT JOIN Bellini.CoursePrerequisite cp ON co.course_id = cp.course_id
LEFT JOIN Bellini.Course prereq_co ON cp.prereq_id = prereq_co.course_id
WHERE co.course_id = @CourseId;

--------------------------------------------------------------------------------
-- 3.8.6: View information of a specific class or all sections of a course
-- Shows schedule, location, instructor, TA, type, status, enrollment, capacity, CRN
-- For Fall 2025 and/or Spring 2026
--------------------------------------------------------------------------------

-- View specific class by course_id and section (e.g., CIS4622.003)
-- Parameters: @ClassCourseId, @ClassSection, @SemesterYear, @SemesterTerm
DECLARE @ClassCourseId CHAR(10) = 'CIS2103';
DECLARE @ClassSection VARCHAR(10) = '001';
DECLARE @SemesterYear INT = 2025;
DECLARE @SemesterTerm VARCHAR(20) = 'Fall';

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    c.type,
    c.status,
    c.total_capacity,
    c.total_enrollment,
    (c.total_capacity - c.total_enrollment) AS seats_available,
    s.year,
    s.term,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    instr.email AS instructor_email,
    CONCAT(ta.first_name, ' ', ta.last_name) AS ta_name,
    ta.email AS ta_email,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    CONCAT(l.building, ' ', l.room) AS location,
    c.notes
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
LEFT JOIN Bellini.Student ta_stud ON c.ta_student_id = ta_stud.student_id
LEFT JOIN Bellini.Person ta ON ta_stud.student_id = ta.person_id
LEFT JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
WHERE c.course_id = @ClassCourseId
    AND c.section = @ClassSection
    AND s.year = @SemesterYear
    AND s.term = @SemesterTerm
ORDER BY cs.day_of_week, cs.start_time;

-- View all sections of a course (e.g., all sections of CIS4622)
-- Parameters: @AllSectionsCourseId, @AllSectionsYear, @AllSectionsTerm
DECLARE @AllSectionsCourseId CHAR(10) = 'CIS2103';
DECLARE @AllSectionsYear INT = 2025;
DECLARE @AllSectionsTerm VARCHAR(20) = 'Fall';

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    c.type,
    c.status,
    c.total_capacity,
    c.total_enrollment,
    (c.total_capacity - c.total_enrollment) AS seats_available,
    s.year,
    s.term,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    instr.email AS instructor_email,
    CONCAT(ta.first_name, ' ', ta.last_name) AS ta_name,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    CONCAT(l.building, ' ', l.room) AS location
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
LEFT JOIN Bellini.Student ta_stud ON c.ta_student_id = ta_stud.student_id
LEFT JOIN Bellini.Person ta ON ta_stud.student_id = ta.person_id
LEFT JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
WHERE c.course_id = @AllSectionsCourseId
    AND s.year = @AllSectionsYear
    AND s.term = @AllSectionsTerm
ORDER BY c.section, cs.day_of_week, cs.start_time;

-- View all classes for Fall 2025 or Spring 2026 (or both)
-- Parameter: @ViewYear, @ViewTerm (can be NULL to view all)
DECLARE @ViewYear INT = NULL; -- NULL for all, or specific year like 2025
DECLARE @ViewTerm VARCHAR(20) = NULL; -- NULL for all, or 'Fall', 'Spring'

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    c.type,
    c.status,
    c.total_capacity,
    c.total_enrollment,
    (c.total_capacity - c.total_enrollment) AS seats_available,
    s.year,
    s.term,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    CONCAT(ta.first_name, ' ', ta.last_name) AS ta_name,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    CONCAT(l.building, ' ', l.room) AS location
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester s ON c.semester_id = s.semester_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
LEFT JOIN Bellini.Student ta_stud ON c.ta_student_id = ta_stud.student_id
LEFT JOIN Bellini.Person ta ON ta_stud.student_id = ta.person_id
LEFT JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
WHERE (@ViewYear IS NULL OR s.year = @ViewYear)
    AND (@ViewTerm IS NULL OR s.term = @ViewTerm)
    AND s.year IN (2025, 2026) -- Limit to Fall 2025 and Spring 2026
ORDER BY s.year, s.term, c.course_id, c.section, cs.day_of_week, cs.start_time;

--------------------------------------------------------------------------------
-- 3.8.7: View information of an instructor or student (including TA)
--------------------------------------------------------------------------------

-- View instructor information by instructor_id
-- Parameter: @InstructorId
DECLARE @InstructorId INT = 1000; -- example person_id

SELECT 
    p.person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    p.email,
    p.phone,
    p.address,
    i.office_location,
    i.office_hours,
    'Instructor' AS person_type
FROM Bellini.Person p
JOIN Bellini.Instructor i ON p.person_id = i.instructor_id
WHERE p.person_id = @InstructorId;

-- View student information by student_id
-- Parameter: @ViewStudentId
DECLARE @ViewStudentId INT = 1003; -- example person_id

SELECT 
    p.person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    p.email,
    p.phone,
    p.address,
    s.major_code,
    m.name AS major_name,
    s.admit_term,
    s.classification,
    s.attempted_hours,
    s.earned_hours,
    s.gpa,
    'Student' AS person_type
FROM Bellini.Person p
JOIN Bellini.Student s ON p.person_id = s.student_id
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE p.person_id = @ViewStudentId;

-- View TA information (students who are TAs for classes)
-- Parameter: @TAStudentId
DECLARE @TAStudentId INT = 1003; -- example student_id who is TA

SELECT 
    p.person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    p.email,
    p.phone,
    s.major_code,
    m.name AS major_name,
    s.classification,
    s.gpa,
    'Teaching Assistant' AS person_type,
    -- Classes where this student is TA
    c.course_id,
    co.title AS course_title,
    c.section,
    sem.year,
    sem.term
FROM Bellini.Person p
JOIN Bellini.Student s ON p.person_id = s.student_id
JOIN Bellini.Major m ON s.major_code = m.major_code
LEFT JOIN Bellini.Class c ON s.student_id = c.ta_student_id
LEFT JOIN Bellini.Course co ON c.course_id = co.course_id
LEFT JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE p.person_id = @TAStudentId;

-- Search for all TAs in the system
SELECT 
    DISTINCT
    p.person_id,
    CONCAT(p.first_name, ' ', p.last_name) AS full_name,
    p.email,
    s.major_code,
    s.gpa,
    COUNT(c.class_id) AS classes_as_ta
FROM Bellini.Person p
JOIN Bellini.Student s ON p.person_id = s.student_id
JOIN Bellini.Class c ON s.student_id = c.ta_student_id
GROUP BY p.person_id, p.first_name, p.last_name, p.email, s.major_code, s.gpa
ORDER BY p.last_name, p.first_name;

--------------------------------------------------------------------------------
-- 3.8.8: Modify Spring 2026 class data
-- Including schedule, instructor, location, total capacity, status
-- Assumes modifications are done by authorized users only
--------------------------------------------------------------------------------

-- Update class instructor for Spring 2026
-- Parameters: @UpdateClassId, @NewInstructorId
DECLARE @UpdateClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @NewInstructorId INT = 1001; -- example instructor person_id

UPDATE Bellini.Class
SET instructor_id = @NewInstructorId
WHERE class_id = @UpdateClassId
    AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring');

-- Update class capacity for Spring 2026
-- Parameters: @UpdateCapacityClassId, @NewCapacity
DECLARE @UpdateCapacityClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @NewCapacity INT = 50;

UPDATE Bellini.Class
SET total_capacity = @NewCapacity
WHERE class_id = @UpdateCapacityClassId
    AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring');

-- Update class status for Spring 2026
-- Parameters: @UpdateStatusClassId, @NewStatus
DECLARE @UpdateStatusClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @NewStatus VARCHAR(20) = 'CLOSED';

UPDATE Bellini.Class
SET status = @NewStatus
WHERE class_id = @UpdateStatusClassId
    AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring');

-- Update class schedule (meeting time) for Spring 2026
-- Parameters: @UpdateScheduleClassId, @ScheduleId, @NewDayOfWeek, @NewStartTime, @NewEndTime
DECLARE @UpdateScheduleClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @ScheduleId INT; -- The schedule_id to update
DECLARE @NewDayOfWeek CHAR(3) = 'Tue';
DECLARE @NewStartTime TIME = '14:00';
DECLARE @NewEndTime TIME = '15:15';

-- First, find the schedule_id for the class (if exists)
SELECT @ScheduleId = schedule_id 
FROM Bellini.ClassSchedule 
WHERE class_id = @UpdateScheduleClassId;

-- Update the schedule if it exists
UPDATE Bellini.ClassSchedule
SET day_of_week = @NewDayOfWeek,
    start_time = @NewStartTime,
    end_time = @NewEndTime
WHERE schedule_id = @ScheduleId
    AND class_id IN (
        SELECT class_id 
        FROM Bellini.Class 
        WHERE semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring')
    );

-- Update class location for Spring 2026
-- Parameters: @UpdateLocationClassId, @UpdateScheduleId, @NewLocationId
DECLARE @UpdateLocationClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @UpdateScheduleId INT; -- The schedule_id to update
DECLARE @NewLocationId INT = 2; -- location_id from Bellini.Location

SELECT @UpdateScheduleId = schedule_id 
FROM Bellini.ClassSchedule 
WHERE class_id = @UpdateLocationClassId;

UPDATE Bellini.ClassSchedule
SET location_id = @NewLocationId
WHERE schedule_id = @UpdateScheduleId
    AND class_id IN (
        SELECT class_id 
        FROM Bellini.Class 
        WHERE semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring')
    );

-- Add a new schedule slot for a Spring 2026 class (e.g., adding a lab session)
-- Parameters: @AddScheduleClassId, @AddDayOfWeek, @AddStartTime, @AddEndTime, @AddLocationId
DECLARE @AddScheduleClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @AddDayOfWeek CHAR(3) = 'Thu';
DECLARE @AddStartTime TIME = '14:00';
DECLARE @AddEndTime TIME = '15:15';
DECLARE @AddLocationId INT = 1;

INSERT INTO Bellini.ClassSchedule (class_id, day_of_week, start_time, end_time, location_id)
SELECT @AddScheduleClassId, @AddDayOfWeek, @AddStartTime, @AddEndTime, @AddLocationId
WHERE EXISTS (
    SELECT 1 
    FROM Bellini.Class 
    WHERE class_id = @AddScheduleClassId 
        AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring')
);

-- Delete a schedule slot for a Spring 2026 class
-- Parameters: @DeleteScheduleId
DECLARE @DeleteScheduleId INT; -- The schedule_id to delete

DELETE FROM Bellini.ClassSchedule
WHERE schedule_id = @DeleteScheduleId
    AND class_id IN (
        SELECT class_id 
        FROM Bellini.Class 
        WHERE semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring')
    );

-- Update class notes for Spring 2026
-- Parameters: @UpdateNotesClassId, @NewNotes
DECLARE @UpdateNotesClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @NewNotes NVARCHAR(400) = 'Prerequisites strictly enforced. Laptop required for in-class exercises.';

UPDATE Bellini.Class
SET notes = @NewNotes
WHERE class_id = @UpdateNotesClassId
    AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring');

-- Update class type for Spring 2026 (e.g., change from Lecture to Lab)
-- Parameters: @UpdateTypeClassId, @NewType
DECLARE @UpdateTypeClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);
DECLARE @NewType VARCHAR(30) = 'Laboratory';

UPDATE Bellini.Class
SET type = @NewType
WHERE class_id = @UpdateTypeClassId
    AND semester_id IN (SELECT semester_id FROM Bellini.Semester WHERE year = 2026 AND term = 'Spring');

--------------------------------------------------------------------------------
-- 3.8.9: List summary of semester and/or accumulated GPA of students
-- Can filter by same major or students of a specific class
-- Summary includes average, highest, lowest, and total students
--------------------------------------------------------------------------------

-- GPA summary for students with the same major
-- Parameter: @GPAMajorCode
DECLARE @GPAMajorCode CHAR(5) = 'BSCS';

SELECT 
    s.major_code,
    m.name AS major_name,
    COUNT(s.student_id) AS total_students,
    AVG(s.gpa) AS average_gpa,
    MAX(s.gpa) AS highest_gpa,
    MIN(s.gpa) AS lowest_gpa,
    COUNT(CASE WHEN s.gpa >= 3.5 THEN 1 END) AS students_above_3_5,
    COUNT(CASE WHEN s.gpa BETWEEN 3.0 AND 3.49 THEN 1 END) AS students_3_0_to_3_49,
    COUNT(CASE WHEN s.gpa BETWEEN 2.5 AND 2.99 THEN 1 END) AS students_2_5_to_2_99,
    COUNT(CASE WHEN s.gpa < 2.5 THEN 1 END) AS students_below_2_5
FROM Bellini.Student s
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE s.major_code = @GPAMajorCode
    AND s.gpa IS NOT NULL
GROUP BY s.major_code, m.name;

-- Detailed list of students by major with their GPA
SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    s.classification,
    s.attempted_hours,
    s.earned_hours,
    s.gpa
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE s.major_code = @GPAMajorCode
    AND s.gpa IS NOT NULL
ORDER BY s.gpa DESC, p.last_name, p.first_name;

-- GPA summary for students enrolled in a specific class
-- Parameter: @GPAClassId or @GPACRNandSemester
DECLARE @GPAClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92002 AND semester_id = 1);

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    sem.year,
    sem.term,
    COUNT(DISTINCT e.student_id) AS total_students,
    AVG(s.gpa) AS average_gpa,
    MAX(s.gpa) AS highest_gpa,
    MIN(s.gpa) AS lowest_gpa
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
JOIN Bellini.Student s ON e.student_id = s.student_id
WHERE c.class_id = @GPAClassId
    AND e.status = 'ENROLLED'
    AND s.gpa IS NOT NULL
GROUP BY c.class_id, c.course_id, co.title, c.section, c.crn, sem.year, sem.term;

-- Detailed list of students in a specific class with their GPA
SELECT 
    e.enrollment_id,
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    s.classification,
    s.gpa,
    e.status AS enrollment_status,
    c.course_id,
    c.section
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.student_id = s.student_id
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
JOIN Bellini.Class c ON e.class_id = c.class_id
WHERE e.class_id = @GPAClassId
    AND e.status = 'ENROLLED'
ORDER BY s.gpa DESC, p.last_name, p.first_name;

-- GPA summary comparison across all majors
SELECT 
    s.major_code,
    m.name AS major_name,
    COUNT(s.student_id) AS total_students,
    AVG(s.gpa) AS average_gpa,
    MAX(s.gpa) AS highest_gpa,
    MIN(s.gpa) AS lowest_gpa
FROM Bellini.Student s
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE s.gpa IS NOT NULL
GROUP BY s.major_code, m.name
ORDER BY average_gpa DESC;

--------------------------------------------------------------------------------
-- 3.8.10: Play what-if scenarios against GPA
-- Answer questions like "How will accumulated GPA change if current registered
-- courses all pass with an A grade, or if one course fails?"
--------------------------------------------------------------------------------

-- Calculate what-if GPA scenario for a student
-- Parameter: @WhatIfStudentId
DECLARE @WhatIfStudentId INT = 1003;

-- Current student status
SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    s.earned_hours AS current_earned_hours,
    s.attempted_hours AS current_attempted_hours,
    s.gpa AS current_gpa,
    -- Calculate quality points from current GPA
    (s.gpa * s.earned_hours) AS current_quality_points
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
WHERE s.student_id = @WhatIfStudentId;

-- Show currently enrolled courses for Spring 2026 (not yet graded)
SELECT 
    e.enrollment_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    c.section,
    sem.year,
    sem.term
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE e.student_id = @WhatIfStudentId
    AND e.status = 'ENROLLED'
    AND e.grade_letter IS NULL -- Not yet graded
    AND sem.year = 2026 AND sem.term = 'Spring';

-- What-if scenario 1: All current enrolled courses pass with A grade (4.0)
WITH CurrentStatus AS (
    SELECT 
        s.student_id,
        s.earned_hours,
        s.gpa,
        (s.gpa * s.earned_hours) AS current_quality_points
    FROM Bellini.Student s
    WHERE s.student_id = @WhatIfStudentId
),
EnrolledCredits AS (
    SELECT 
        SUM(co.credits) AS total_new_credits
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @WhatIfStudentId
        AND e.status = 'ENROLLED'
        AND e.grade_letter IS NULL
        AND sem.year = 2026 AND sem.term = 'Spring'
)
SELECT 
    cs.student_id,
    cs.gpa AS current_gpa,
    cs.earned_hours AS current_earned_hours,
    ec.total_new_credits,
    -- If all A's (4.0 grade points)
    (cs.current_quality_points + (ec.total_new_credits * 4.0)) / (cs.earned_hours + ec.total_new_credits) AS gpa_if_all_A,
    ((cs.current_quality_points + (ec.total_new_credits * 4.0)) / (cs.earned_hours + ec.total_new_credits)) - cs.gpa AS gpa_change_all_A
FROM CurrentStatus cs
CROSS JOIN EnrolledCredits ec;

-- What-if scenario 2: All current enrolled courses pass with B grade (3.0)
WITH CurrentStatus AS (
    SELECT 
        s.student_id,
        s.earned_hours,
        s.gpa,
        (s.gpa * s.earned_hours) AS current_quality_points
    FROM Bellini.Student s
    WHERE s.student_id = @WhatIfStudentId
),
EnrolledCredits AS (
    SELECT 
        SUM(co.credits) AS total_new_credits
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @WhatIfStudentId
        AND e.status = 'ENROLLED'
        AND e.grade_letter IS NULL
        AND sem.year = 2026 AND sem.term = 'Spring'
)
SELECT 
    cs.student_id,
    cs.gpa AS current_gpa,
    cs.earned_hours AS current_earned_hours,
    ec.total_new_credits,
    -- If all B's (3.0 grade points)
    (cs.current_quality_points + (ec.total_new_credits * 3.0)) / (cs.earned_hours + ec.total_new_credits) AS gpa_if_all_B,
    ((cs.current_quality_points + (ec.total_new_credits * 3.0)) / (cs.earned_hours + ec.total_new_credits)) - cs.gpa AS gpa_change_all_B
FROM CurrentStatus cs
CROSS JOIN EnrolledCredits ec;

-- What-if scenario 3: One course fails (0.0), rest pass with current GPA
-- Parameter: @FailCourseId - the course that would fail
DECLARE @FailCourseId CHAR(10) = 'CIS2103';

WITH CurrentStatus AS (
    SELECT 
        s.student_id,
        s.earned_hours,
        s.gpa,
        (s.gpa * s.earned_hours) AS current_quality_points
    FROM Bellini.Student s
    WHERE s.student_id = @WhatIfStudentId
),
EnrolledCourses AS (
    SELECT 
        co.course_id,
        co.credits,
        CASE 
            WHEN co.course_id = @FailCourseId THEN 0.0  -- Failed course
            ELSE 3.0  -- Assume B grade for others
        END AS assumed_grade_points
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @WhatIfStudentId
        AND e.status = 'ENROLLED'
        AND e.grade_letter IS NULL
        AND sem.year = 2026 AND sem.term = 'Spring'
),
NewQualityPoints AS (
    SELECT 
        SUM(credits) AS total_new_credits,
        SUM(credits * assumed_grade_points) AS total_new_quality_points
    FROM EnrolledCourses
)
SELECT 
    cs.student_id,
    cs.gpa AS current_gpa,
    cs.earned_hours AS current_earned_hours,
    nqp.total_new_credits,
    @FailCourseId AS failed_course,
    -- New GPA if one course fails
    (cs.current_quality_points + nqp.total_new_quality_points) / (cs.earned_hours + nqp.total_new_credits) AS gpa_if_one_fails,
    ((cs.current_quality_points + nqp.total_new_quality_points) / (cs.earned_hours + nqp.total_new_credits)) - cs.gpa AS gpa_change_one_fails
FROM CurrentStatus cs
CROSS JOIN NewQualityPoints nqp;

-- What-if scenario 4: Custom grades for each enrolled course
-- This query allows setting specific grade points for each course
WITH CurrentStatus AS (
    SELECT 
        s.student_id,
        CONCAT(p.first_name, ' ', p.last_name) AS student_name,
        s.earned_hours,
        s.gpa,
        (s.gpa * s.earned_hours) AS current_quality_points
    FROM Bellini.Student s
    JOIN Bellini.Person p ON s.student_id = p.person_id
    WHERE s.student_id = @WhatIfStudentId
),
-- Example: Manually specify expected grades for each course
ExpectedGrades AS (
    SELECT 
        co.course_id,
        co.title,
        co.credits,
        -- Assign expected grade points (modify as needed)
        CASE co.course_id
            WHEN 'CIS2103' THEN 4.0  -- Expect A
            WHEN 'CIS3207' THEN 3.0  -- Expect B
            ELSE 3.5  -- Default to B+ for others
        END AS expected_grade_points
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @WhatIfStudentId
        AND e.status = 'ENROLLED'
        AND e.grade_letter IS NULL
        AND sem.year = 2026 AND sem.term = 'Spring'
),
NewTotals AS (
    SELECT 
        SUM(credits) AS total_new_credits,
        SUM(credits * expected_grade_points) AS total_new_quality_points
    FROM ExpectedGrades
)
SELECT 
    cs.student_id,
    cs.student_name,
    cs.current_gpa,
    cs.earned_hours AS current_earned_hours,
    nt.total_new_credits,
    (cs.current_quality_points + nt.total_new_quality_points) / (cs.earned_hours + nt.total_new_credits) AS projected_new_gpa,
    ((cs.current_quality_points + nt.total_new_quality_points) / (cs.earned_hours + nt.total_new_credits)) - cs.current_gpa AS gpa_change
FROM CurrentStatus cs
CROSS JOIN NewTotals nt;

-- Show breakdown of expected grades per course
SELECT 
    co.course_id,
    co.title,
    co.credits,
    CASE co.course_id
        WHEN 'CIS2103' THEN 'A (4.0)'
        WHEN 'CIS3207' THEN 'B (3.0)'
        ELSE 'B+ (3.5)'
    END AS expected_grade
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE e.student_id = @WhatIfStudentId
    AND e.status = 'ENROLLED'
    AND e.grade_letter IS NULL
    AND sem.year = 2026 AND sem.term = 'Spring';

--------------------------------------------------------------------------------
-- 3.8.11: View semester transcript or overall (accumulated) transcript
-- For student users, limited to their own transcript (RLS assumed for future)
--------------------------------------------------------------------------------

-- View semester transcript for a specific student and semester
-- Parameters: @TranscriptStudentId, @TranscriptYear, @TranscriptTerm
DECLARE @TranscriptStudentId INT = 1003;
DECLARE @TranscriptYear INT = 2025;
DECLARE @TranscriptTerm VARCHAR(20) = 'Fall';

SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    sem.year,
    sem.term,
    c.course_id,
    co.title AS course_title,
    c.section,
    co.credits,
    e.grade_letter,
    e.grade_points,
    e.status
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
JOIN Bellini.Enrollment e ON s.student_id = e.student_id
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE s.student_id = @TranscriptStudentId
    AND sem.year = @TranscriptYear
    AND sem.term = @TranscriptTerm
    AND e.status IN ('ENROLLED', 'COMPLETED')
ORDER BY co.course_id;

-- Semester transcript summary (GPA for that semester)
WITH SemesterCourses AS (
    SELECT 
        co.credits,
        ISNULL(e.grade_points, 0) AS grade_points
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @TranscriptStudentId
        AND sem.year = @TranscriptYear
        AND sem.term = @TranscriptTerm
        AND e.status IN ('ENROLLED', 'COMPLETED')
        AND e.grade_letter IS NOT NULL
)
SELECT 
    @TranscriptYear AS year,
    @TranscriptTerm AS term,
    SUM(credits) AS semester_credits,
    SUM(credits * grade_points) AS semester_quality_points,
    CASE 
        WHEN SUM(credits) > 0 THEN SUM(credits * grade_points) / SUM(credits)
        ELSE 0
    END AS semester_gpa
FROM SemesterCourses;

-- View overall (accumulated) transcript for a student
-- Parameter: @OverallTranscriptStudentId
DECLARE @OverallTranscriptStudentId INT = 1003;

SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    sem.year,
    sem.term,
    c.course_id,
    co.title AS course_title,
    c.section,
    co.credits,
    e.grade_letter,
    e.grade_points,
    e.status,
    e.enroll_date
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
JOIN Bellini.Enrollment e ON s.student_id = e.student_id
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE s.student_id = @OverallTranscriptStudentId
    AND e.status IN ('ENROLLED', 'COMPLETED')
ORDER BY sem.year, sem.term, co.course_id;

-- Overall transcript summary
SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    s.major_code,
    m.name AS major_name,
    s.admit_term,
    s.classification,
    s.attempted_hours AS total_attempted_hours,
    s.earned_hours AS total_earned_hours,
    s.gpa AS cumulative_gpa
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE s.student_id = @OverallTranscriptStudentId;

-- Transcript grouped by semester
SELECT 
    sem.year,
    sem.term,
    COUNT(e.enrollment_id) AS courses_taken,
    SUM(co.credits) AS semester_credits,
    AVG(e.grade_points) AS semester_avg_grade_points
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE e.student_id = @OverallTranscriptStudentId
    AND e.status IN ('ENROLLED', 'COMPLETED')
    AND e.grade_letter IS NOT NULL
GROUP BY sem.year, sem.term
ORDER BY sem.year, sem.term;

--------------------------------------------------------------------------------
-- 3.8.12: Register courses for Spring 2026 and view weekly class schedule
-- Validate course requests and update enrollment, status, and attempted hours
--------------------------------------------------------------------------------

-- Step 1: Check if course exists
-- Parameter: @RegisterCourseId
DECLARE @RegisterCourseId CHAR(10) = 'CIS3207';

SELECT course_id, title, credits, level
FROM Bellini.Course
WHERE course_id = @RegisterCourseId;

-- Step 2: Check if class is available for Spring 2026
-- Parameters: @RegisterCourseId, @RegisterSection
DECLARE @RegisterSection VARCHAR(10) = '001';
DECLARE @RegisterClassId INT;

SELECT @RegisterClassId = c.class_id
FROM Bellini.Class c
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE c.course_id = @RegisterCourseId
    AND c.section = @RegisterSection
    AND sem.year = 2026
    AND sem.term = 'Spring'
    AND c.status = 'OPEN'
    AND c.total_enrollment < c.total_capacity;

-- Step 3: Validate registration for a student
-- Parameter: @RegisterStudentId
DECLARE @RegisterStudentId INT = 1003;

-- Check if course is acceptable by student's major
SELECT 
    s.student_id,
    s.major_code,
    mc.course_id,
    mc.required_type
FROM Bellini.Student s
JOIN Bellini.MajorCourse mc ON s.major_code = mc.major_code
WHERE s.student_id = @RegisterStudentId
    AND mc.course_id = @RegisterCourseId;

-- Check for duplicate enrollment (same course in current or past semesters)
SELECT e.enrollment_id, c.course_id, c.section, sem.year, sem.term
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
WHERE e.student_id = @RegisterStudentId
    AND c.course_id = @RegisterCourseId
    AND e.status IN ('ENROLLED', 'COMPLETED');

-- Check if student meets prerequisites
WITH StudentCompletedCourses AS (
    SELECT DISTINCT cl.course_id
    FROM Bellini.Enrollment e
    JOIN Bellini.Class cl ON e.class_id = cl.class_id
    WHERE e.student_id = @RegisterStudentId
        AND e.status = 'COMPLETED'
        AND e.grade_letter IS NOT NULL
        AND e.grade_points >= 2.0  -- Passed with C or better
)
SELECT 
    cp.course_id,
    cp.prereq_id,
    co.title AS prereq_title,
    CASE WHEN scc.course_id IS NOT NULL THEN 'Met' ELSE 'Not Met' END AS prereq_status
FROM Bellini.CoursePrerequisite cp
JOIN Bellini.Course co ON cp.prereq_id = co.course_id
LEFT JOIN StudentCompletedCourses scc ON cp.prereq_id = scc.course_id
WHERE cp.course_id = @RegisterCourseId
    AND cp.is_corequisite = 0;

-- Check total semester hours (should not exceed 18)
WITH Spring2026Enrollments AS (
    SELECT SUM(co.credits) AS current_spring_credits
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE e.student_id = @RegisterStudentId
        AND sem.year = 2026
        AND sem.term = 'Spring'
        AND e.status = 'ENROLLED'
)
SELECT 
    current_spring_credits,
    (SELECT credits FROM Bellini.Course WHERE course_id = @RegisterCourseId) AS course_credits,
    current_spring_credits + (SELECT credits FROM Bellini.Course WHERE course_id = @RegisterCourseId) AS total_if_registered,
    CASE 
        WHEN current_spring_credits + (SELECT credits FROM Bellini.Course WHERE course_id = @RegisterCourseId) <= 18 
        THEN 'OK' 
        ELSE 'Exceeds Maximum (18)' 
    END AS validation_status
FROM Spring2026Enrollments;

-- Step 4: Perform registration (INSERT into Enrollment)
-- This assumes all validations passed
INSERT INTO Bellini.Enrollment (class_id, student_id, status)
SELECT @RegisterClassId, @RegisterStudentId, 'ENROLLED'
WHERE @RegisterClassId IS NOT NULL
    AND NOT EXISTS (
        -- Prevent duplicate enrollment
        SELECT 1 
        FROM Bellini.Enrollment e2 
        WHERE e2.class_id = @RegisterClassId 
            AND e2.student_id = @RegisterStudentId
    );

-- Step 5: Update student's attempted hours after registration
UPDATE s
SET s.attempted_hours = s.attempted_hours + co.credits
FROM Bellini.Student s
CROSS APPLY (
    SELECT SUM(co2.credits) AS credits
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co2 ON c.course_id = co2.course_id
    WHERE e.student_id = @RegisterStudentId
        AND e.class_id = @RegisterClassId
        AND e.status = 'ENROLLED'
) co
WHERE s.student_id = @RegisterStudentId;

-- Step 6: View weekly class schedule for a student
-- Parameter: @ScheduleStudentId, @ScheduleYear, @ScheduleTerm
DECLARE @ScheduleStudentId INT = 1003;
DECLARE @ScheduleYear INT = 2026;
DECLARE @ScheduleTerm VARCHAR(20) = 'Spring';

SELECT 
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    CONCAT(l.building, ' ', l.room) AS location,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name
FROM Bellini.Student s
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Enrollment e ON s.student_id = e.student_id
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
LEFT JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
WHERE s.student_id = @ScheduleStudentId
    AND sem.year = @ScheduleYear
    AND sem.term = @ScheduleTerm
    AND e.status = 'ENROLLED'
ORDER BY 
    CASE cs.day_of_week
        WHEN 'Mon' THEN 1
        WHEN 'Tue' THEN 2
        WHEN 'Wed' THEN 3
        WHEN 'Thu' THEN 4
        WHEN 'Fri' THEN 5
        WHEN 'Sat' THEN 6
        WHEN 'Sun' THEN 7
    END,
    cs.start_time;

--------------------------------------------------------------------------------
-- 3.8.13: Drop or add a course to change course registration
-- Validate requests and update enrollment accordingly
--------------------------------------------------------------------------------

-- Drop a course - Step 1: Validate drop request
-- Parameters: @DropStudentId, @DropClassId
DECLARE @DropStudentId INT = 1003;
DECLARE @DropClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93001 AND semester_id = 2);

-- Check if student is enrolled in the class
SELECT 
    e.enrollment_id,
    e.student_id,
    e.class_id,
    c.course_id,
    co.title,
    c.section,
    e.status
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
WHERE e.student_id = @DropStudentId
    AND e.class_id = @DropClassId
    AND e.status = 'ENROLLED';

-- Check if course is a corequisite for another enrolled course
WITH DroppingCourse AS (
    SELECT c.course_id
    FROM Bellini.Class c
    WHERE c.class_id = @DropClassId
),
EnrolledCourses AS (
    SELECT DISTINCT cl.course_id
    FROM Bellini.Enrollment e
    JOIN Bellini.Class cl ON e.class_id = cl.class_id
    WHERE e.student_id = @DropStudentId
        AND e.status = 'ENROLLED'
        AND cl.class_id <> @DropClassId
)
SELECT 
    ec.course_id AS enrolled_course,
    co.title AS enrolled_course_title,
    cp.prereq_id AS required_corequisite,
    co2.title AS corequisite_title,
    'Cannot drop - required as corequisite' AS warning
FROM EnrolledCourses ec
JOIN Bellini.Course co ON ec.course_id = co.course_id
JOIN Bellini.CoursePrerequisite cp ON ec.course_id = cp.course_id
JOIN Bellini.Course co2 ON cp.prereq_id = co2.course_id
CROSS JOIN DroppingCourse dc
WHERE cp.prereq_id = dc.course_id
    AND cp.is_corequisite = 1;

-- Drop a course - Step 2: Update enrollment status to DROPPED
UPDATE Bellini.Enrollment
SET status = 'DROPPED'
WHERE student_id = @DropStudentId
    AND class_id = @DropClassId
    AND status = 'ENROLLED';

-- Drop a course - Step 3: Update student attempted hours (decrease)
UPDATE s
SET s.attempted_hours = s.attempted_hours - co.credits
FROM Bellini.Student s
JOIN Bellini.Class c ON c.class_id = @DropClassId
JOIN Bellini.Course co ON c.course_id = co.course_id
WHERE s.student_id = @DropStudentId;

-- Add a course - Step 1: Validate add request (check prerequisites)
-- Parameters: @AddStudentId, @AddClassId, @AddCourseId
DECLARE @AddStudentId INT = 1003;
DECLARE @AddClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 93002 AND semester_id = 2);
DECLARE @AddCourseId CHAR(10) = 'CIS3207';

-- Check if student meets prerequisites for the course
WITH StudentCompletedCourses AS (
    SELECT DISTINCT cl.course_id
    FROM Bellini.Enrollment e
    JOIN Bellini.Class cl ON e.class_id = cl.class_id
    WHERE e.student_id = @AddStudentId
        AND e.status = 'COMPLETED'
        AND e.grade_points >= 2.0
),
MissingPrereqs AS (
    SELECT 
        cp.course_id,
        cp.prereq_id,
        co.title AS prereq_title,
        CASE WHEN cp.is_corequisite = 1 THEN 'Corequisite' ELSE 'Prerequisite' END AS req_type
    FROM Bellini.CoursePrerequisite cp
    JOIN Bellini.Course co ON cp.prereq_id = co.course_id
    LEFT JOIN StudentCompletedCourses scc ON cp.prereq_id = scc.course_id
    WHERE cp.course_id = @AddCourseId
        AND cp.is_corequisite = 0
        AND scc.course_id IS NULL
)
SELECT * FROM MissingPrereqs;

-- Check if class is available (open and has capacity)
SELECT 
    c.class_id,
    c.course_id,
    c.section,
    c.status,
    c.total_capacity,
    c.total_enrollment,
    (c.total_capacity - c.total_enrollment) AS seats_available,
    CASE 
        WHEN c.status = 'CLOSED' THEN 'Class is closed'
        WHEN c.total_enrollment >= c.total_capacity THEN 'Class is full'
        ELSE 'Available'
    END AS availability_status
FROM Bellini.Class c
WHERE c.class_id = @AddClassId;

-- Add a course - Step 2: Perform add (INSERT)
INSERT INTO Bellini.Enrollment (class_id, student_id, status)
SELECT @AddClassId, @AddStudentId, 'ENROLLED'
WHERE @AddClassId IS NOT NULL
    AND NOT EXISTS (
        SELECT 1 
        FROM Bellini.Enrollment e 
        WHERE e.class_id = @AddClassId 
            AND e.student_id = @AddStudentId
    );

-- Add a course - Step 3: Update student attempted hours (increase)
UPDATE s
SET s.attempted_hours = s.attempted_hours + co.credits
FROM Bellini.Student s
JOIN Bellini.Class c ON c.class_id = @AddClassId
JOIN Bellini.Course co ON c.course_id = co.course_id
WHERE s.student_id = @AddStudentId;

--------------------------------------------------------------------------------
-- 3.8.14: Instructors enter or modify grades for their own Fall 2025 classes
-- Security policy assumed to be implemented in future phase
--------------------------------------------------------------------------------

-- Enter grade for a student in a Fall 2025 class
-- Parameters: @GradeInstructorId, @GradeEnrollmentId, @GradeLetter, @GradePoints
DECLARE @GradeInstructorId INT = 1000; -- instructor person_id
DECLARE @GradeEnrollmentId INT = 1; -- enrollment_id
DECLARE @GradeLetter VARCHAR(5) = 'B+';
DECLARE @GradePoints DECIMAL(4,2) = 3.33;

-- Step 1: Verify instructor teaches this class (Fall 2025)
SELECT 
    e.enrollment_id,
    e.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    c.class_id,
    c.course_id,
    co.title,
    c.section,
    c.instructor_id,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    sem.year,
    sem.term
FROM Bellini.Enrollment e
JOIN Bellini.Class c ON e.class_id = c.class_id
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Person p ON e.student_id = p.person_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
WHERE e.enrollment_id = @GradeEnrollmentId
    AND c.instructor_id = @GradeInstructorId
    AND sem.year = 2025
    AND sem.term = 'Fall';

-- Step 2: Insert grade entry record
INSERT INTO Bellini.GradeEntry (enrollment_id, entered_by, grade_letter, grade_points, comment)
VALUES (@GradeEnrollmentId, @GradeInstructorId, @GradeLetter, @GradePoints, 'Final grade entered');

-- Step 3: Update enrollment record with grade
UPDATE Bellini.Enrollment
SET grade_letter = @GradeLetter,
    grade_points = @GradePoints,
    status = 'COMPLETED'
WHERE enrollment_id = @GradeEnrollmentId;

-- Modify existing grade
-- Parameters: @ModifyEnrollmentId, @NewGradeLetter, @NewGradePoints
DECLARE @ModifyEnrollmentId INT = 1;
DECLARE @NewGradeLetter VARCHAR(5) = 'A';
DECLARE @NewGradePoints DECIMAL(4,2) = 4.0;

-- Step 1: Insert new grade entry (for audit trail)
INSERT INTO Bellini.GradeEntry (enrollment_id, entered_by, grade_letter, grade_points, comment)
VALUES (@ModifyEnrollmentId, @GradeInstructorId, @NewGradeLetter, @NewGradePoints, 'Grade modified');

-- Step 2: Update enrollment with new grade
UPDATE Bellini.Enrollment
SET grade_letter = @NewGradeLetter,
    grade_points = @NewGradePoints
WHERE enrollment_id = @ModifyEnrollmentId;

-- View all grades entered by an instructor for Fall 2025
-- Parameter: @ViewGradesInstructorId
DECLARE @ViewGradesInstructorId INT = 1000;

SELECT 
    c.course_id,
    co.title AS course_title,
    c.section,
    e.enrollment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    e.grade_letter,
    e.grade_points,
    e.status,
    ge.entry_date AS last_grade_entry
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
JOIN Bellini.Student s ON e.student_id = s.student_id
JOIN Bellini.Person p ON s.student_id = p.person_id
LEFT JOIN Bellini.GradeEntry ge ON e.enrollment_id = ge.enrollment_id
WHERE c.instructor_id = @ViewGradesInstructorId
    AND sem.year = 2025
    AND sem.term = 'Fall'
ORDER BY c.course_id, c.section, p.last_name, p.first_name;

-- Bulk grade entry for multiple students in a class
-- This would typically be done in application code with a loop or table-valued parameter
-- Example for demonstration:
DECLARE @BulkGradeClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92002 AND semester_id = 1);
DECLARE @BulkGradeInstructorId INT = 1000;

-- Example: Update grades for all students in the class
-- In practice, this would use a temp table or table variable with student_id and their respective grades
UPDATE e
SET e.grade_letter = 'B',  -- This is simplified; real implementation would have per-student grades
    e.grade_points = 3.0,
    e.status = 'COMPLETED'
FROM Bellini.Enrollment e
WHERE e.class_id = @BulkGradeClassId
    AND EXISTS (
        SELECT 1 
        FROM Bellini.Class c 
        WHERE c.class_id = e.class_id 
            AND c.instructor_id = @BulkGradeInstructorId
    );

--------------------------------------------------------------------------------
-- 3.8.15: View details of a class including enrollment and roster
-- With/without student details like major, earned hours, GPA
-- For Fall 2025 or Spring 2026
--------------------------------------------------------------------------------

-- View class details with enrollment count (summary)
-- Parameters: @RosterClassId or @RosterCRN and @RosterSemesterId
DECLARE @RosterClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92002 AND semester_id = 1);

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    co.credits,
    c.section,
    c.crn,
    c.type,
    c.status,
    c.total_capacity,
    c.total_enrollment,
    (c.total_capacity - c.total_enrollment) AS seats_available,
    sem.year,
    sem.term,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    instr.email AS instructor_email,
    CONCAT(ta.first_name, ' ', ta.last_name) AS ta_name
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
LEFT JOIN Bellini.Student ta_stud ON c.ta_student_id = ta_stud.student_id
LEFT JOIN Bellini.Person ta ON ta_stud.student_id = ta.person_id
WHERE c.class_id = @RosterClassId;

-- View class roster without student details (just names and enrollment status)
SELECT 
    e.enrollment_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    p.email AS student_email,
    e.status AS enrollment_status,
    e.enroll_date,
    e.grade_letter
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.student_id = s.student_id
JOIN Bellini.Person p ON s.student_id = p.person_id
WHERE e.class_id = @RosterClassId
    AND e.status = 'ENROLLED'
ORDER BY p.last_name, p.first_name;

-- View class roster WITH student details (major, hours, GPA)
SELECT 
    e.enrollment_id,
    s.student_id,
    CONCAT(p.first_name, ' ', p.last_name) AS student_name,
    p.email AS student_email,
    s.major_code,
    m.name AS major_name,
    s.classification,
    s.attempted_hours,
    s.earned_hours,
    s.gpa,
    e.status AS enrollment_status,
    e.enroll_date,
    e.grade_letter,
    e.grade_points
FROM Bellini.Enrollment e
JOIN Bellini.Student s ON e.student_id = s.student_id
JOIN Bellini.Person p ON s.student_id = p.person_id
JOIN Bellini.Major m ON s.major_code = m.major_code
WHERE e.class_id = @RosterClassId
    AND e.status = 'ENROLLED'
ORDER BY p.last_name, p.first_name;

-- View class roster with schedule information
SELECT 
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    sem.year,
    sem.term,
    cs.day_of_week,
    cs.start_time,
    cs.end_time,
    CONCAT(l.building, ' ', l.room) AS location,
    COUNT(e.enrollment_id) AS enrolled_students,
    c.total_capacity,
    STRING_AGG(CONCAT(p.last_name, ', ', p.first_name), '; ') AS student_list
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
LEFT JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
LEFT JOIN Bellini.Enrollment e ON c.class_id = e.class_id AND e.status = 'ENROLLED'
LEFT JOIN Bellini.Student s ON e.student_id = s.student_id
LEFT JOIN Bellini.Person p ON s.student_id = p.person_id
WHERE c.class_id = @RosterClassId
GROUP BY c.course_id, co.title, c.section, c.crn, sem.year, sem.term,
         cs.day_of_week, cs.start_time, cs.end_time, l.building, l.room, c.total_capacity;

-- View all classes for an instructor with enrollment counts
-- Parameter: @RosterInstructorId
DECLARE @RosterInstructorId INT = 1000;

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    sem.year,
    sem.term,
    c.total_capacity,
    c.total_enrollment,
    COUNT(e.enrollment_id) AS actual_enrolled_count
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
LEFT JOIN Bellini.Enrollment e ON c.class_id = e.class_id AND e.status = 'ENROLLED'
WHERE c.instructor_id = @RosterInstructorId
    AND sem.year IN (2025, 2026)
GROUP BY c.class_id, c.course_id, co.title, c.section, c.crn, 
         sem.year, sem.term, c.total_capacity, c.total_enrollment
ORDER BY sem.year, sem.term, c.course_id, c.section;

--------------------------------------------------------------------------------
-- 3.8.16: List grade summary for Fall 2025 classes with grades available
-- Include total enrollment, average, highest/lowest grades, grade distribution
--------------------------------------------------------------------------------

-- Grade summary for a specific Fall 2025 class
-- Parameter: @GradeSummaryClassId
DECLARE @GradeSummaryClassId INT = (SELECT class_id FROM Bellini.Class WHERE crn = 92002 AND semester_id = 1);

SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    sem.year,
    sem.term,
    COUNT(e.enrollment_id) AS total_enrollment,
    AVG(e.grade_points) AS grade_average,
    MAX(e.grade_points) AS highest_grade,
    MIN(e.grade_points) AS lowest_grade,
    -- Grade distribution
    COUNT(CASE WHEN e.grade_points >= 3.7 THEN 1 END) AS count_A_range,  -- A-, A
    COUNT(CASE WHEN e.grade_points >= 2.7 AND e.grade_points < 3.7 THEN 1 END) AS count_B_range,  -- B-, B, B+
    COUNT(CASE WHEN e.grade_points >= 1.7 AND e.grade_points < 2.7 THEN 1 END) AS count_C_range,  -- C-, C, C+
    COUNT(CASE WHEN e.grade_points >= 0.7 AND e.grade_points < 1.7 THEN 1 END) AS count_D_range,  -- D-, D, D+
    COUNT(CASE WHEN e.grade_points < 0.7 AND e.grade_points IS NOT NULL THEN 1 END) AS count_F,
    -- Percentage distributions
    CAST(COUNT(CASE WHEN e.grade_points >= 3.7 THEN 1 END) * 100.0 / COUNT(e.enrollment_id) AS DECIMAL(5,2)) AS percent_A_range,
    CAST(COUNT(CASE WHEN e.grade_points >= 2.7 AND e.grade_points < 3.7 THEN 1 END) * 100.0 / COUNT(e.enrollment_id) AS DECIMAL(5,2)) AS percent_B_range,
    CAST(COUNT(CASE WHEN e.grade_points >= 1.7 AND e.grade_points < 2.7 THEN 1 END) * 100.0 / COUNT(e.enrollment_id) AS DECIMAL(5,2)) AS percent_C_range,
    CAST(COUNT(CASE WHEN e.grade_points >= 0.7 AND e.grade_points < 1.7 THEN 1 END) * 100.0 / COUNT(e.enrollment_id) AS DECIMAL(5,2)) AS percent_D_range,
    CAST(COUNT(CASE WHEN e.grade_points < 0.7 AND e.grade_points IS NOT NULL THEN 1 END) * 100.0 / COUNT(e.enrollment_id) AS DECIMAL(5,2)) AS percent_F
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
WHERE c.class_id = @GradeSummaryClassId
    AND e.grade_letter IS NOT NULL
    AND e.grade_points IS NOT NULL
GROUP BY c.class_id, c.course_id, co.title, c.section, c.crn, sem.year, sem.term;

-- Detailed grade distribution with more granular ranges
SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    COUNT(e.enrollment_id) AS total_enrollment,
    -- Detailed percentage ranges
    COUNT(CASE WHEN e.grade_points >= 3.85 THEN 1 END) AS count_above_90_percent,
    COUNT(CASE WHEN e.grade_points >= 3.0 AND e.grade_points < 3.85 THEN 1 END) AS count_80_to_90_percent,
    COUNT(CASE WHEN e.grade_points >= 2.0 AND e.grade_points < 3.0 THEN 1 END) AS count_70_to_80_percent,
    COUNT(CASE WHEN e.grade_points >= 1.0 AND e.grade_points < 2.0 THEN 1 END) AS count_60_to_70_percent,
    COUNT(CASE WHEN e.grade_points < 1.0 AND e.grade_points IS NOT NULL THEN 1 END) AS count_below_60_percent
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
WHERE c.class_id = @GradeSummaryClassId
    AND e.grade_letter IS NOT NULL
    AND e.grade_points IS NOT NULL
GROUP BY c.class_id, c.course_id, co.title, c.section;

-- Grade summary for all Fall 2025 classes with grades
SELECT 
    c.class_id,
    c.course_id,
    co.title AS course_title,
    c.section,
    c.crn,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    COUNT(e.enrollment_id) AS total_enrollment,
    CAST(AVG(e.grade_points) AS DECIMAL(3,2)) AS grade_average,
    MAX(e.grade_points) AS highest_grade,
    MIN(e.grade_points) AS lowest_grade,
    COUNT(CASE WHEN e.grade_points >= 3.7 THEN 1 END) AS count_A_range,
    COUNT(CASE WHEN e.grade_points >= 2.7 AND e.grade_points < 3.7 THEN 1 END) AS count_B_range,
    COUNT(CASE WHEN e.grade_points < 2.0 THEN 1 END) AS count_below_C
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
WHERE sem.year = 2025
    AND sem.term = 'Fall'
    AND e.grade_letter IS NOT NULL
    AND e.grade_points IS NOT NULL
GROUP BY c.class_id, c.course_id, co.title, c.section, c.crn, instr.first_name, instr.last_name
ORDER BY c.course_id, c.section;

-- Grade letter distribution for a Fall 2025 class
SELECT 
    c.course_id,
    co.title AS course_title,
    c.section,
    e.grade_letter,
    COUNT(*) AS student_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percentage
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
WHERE c.class_id = @GradeSummaryClassId
    AND e.grade_letter IS NOT NULL
GROUP BY c.course_id, co.title, c.section, e.grade_letter
ORDER BY 
    CASE e.grade_letter
        WHEN 'A' THEN 1 WHEN 'A-' THEN 2
        WHEN 'B+' THEN 3 WHEN 'B' THEN 4 WHEN 'B-' THEN 5
        WHEN 'C+' THEN 6 WHEN 'C' THEN 7 WHEN 'C-' THEN 8
        WHEN 'D+' THEN 9 WHEN 'D' THEN 10 WHEN 'D-' THEN 11
        WHEN 'F' THEN 12
        ELSE 13
    END;

-- Compare grade distributions across multiple sections of the same course
-- Parameter: @CompareGradeCourseId
DECLARE @CompareGradeCourseId CHAR(10) = 'CIS2103';

SELECT 
    c.course_id,
    co.title AS course_title,
    c.section,
    CONCAT(instr.first_name, ' ', instr.last_name) AS instructor_name,
    COUNT(e.enrollment_id) AS total_enrollment,
    CAST(AVG(e.grade_points) AS DECIMAL(3,2)) AS grade_average,
    MAX(e.grade_points) AS highest_grade,
    MIN(e.grade_points) AS lowest_grade,
    STDEV(e.grade_points) AS grade_std_dev
FROM Bellini.Class c
JOIN Bellini.Course co ON c.course_id = co.course_id
JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
JOIN Bellini.Enrollment e ON c.class_id = e.class_id
LEFT JOIN Bellini.Person instr ON c.instructor_id = instr.person_id
WHERE c.course_id = @CompareGradeCourseId
    AND sem.year = 2025
    AND sem.term = 'Fall'
    AND e.grade_letter IS NOT NULL
    AND e.grade_points IS NOT NULL
GROUP BY c.course_id, co.title, c.section, instr.first_name, instr.last_name
ORDER BY c.section;

GO
