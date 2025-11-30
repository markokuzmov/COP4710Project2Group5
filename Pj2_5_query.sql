-- Query file for Pj2_5 (SQL Server)
-- Converted to Stored Functions (for queries) and Stored Procedures (for modifications)
-- to support functional requirements 3.8.1 through 3.8.16

USE [Pj2_5];
GO

--------------------------------------------------------------------------------
-- 3.8.1: View list of classes available for registration
-- Function: Bellini.fn_SearchClasses
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_SearchClasses (
    @CoursePrefix NVARCHAR(10) = NULL,
    @CourseNumber NVARCHAR(10) = NULL,
    @CreditHours DECIMAL(3,1) = NULL,
    @CourseLevel INT = NULL
)
RETURNS TABLE
AS
RETURN
(
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
        AND (@CoursePrefix IS NULL OR co.course_id LIKE @CoursePrefix + '%')
        AND (@CourseNumber IS NULL OR co.course_id LIKE '%' + @CourseNumber)
        AND (@CreditHours IS NULL OR co.credits = @CreditHours)
        AND (@CourseLevel IS NULL OR co.level = @CourseLevel)
);
GO

--------------------------------------------------------------------------------
-- 3.8.2: View courses and total hours required by a major
-- Function: Bellini.fn_GetMajorRequirements
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetMajorRequirements (@MajorCode CHAR(5))
RETURNS TABLE
AS
RETURN
(
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
);
GO

--------------------------------------------------------------------------------
-- 3.8.3: View courses not yet registered but required by a major
-- Function: Bellini.fn_GetStudentRemainingRequirements
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetStudentRemainingRequirements (@StudentId INT)
RETURNS TABLE
AS
RETURN
(
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
        mc.semester_recommended,
        (m.total_req_hours - s.earned_hours) AS total_hours_remaining_for_degree
    FROM Bellini.Student s
    JOIN Bellini.Person p ON s.student_id = p.person_id
    JOIN Bellini.Major m ON s.major_code = m.major_code
    JOIN Bellini.MajorCourse mc ON m.major_code = mc.major_code
    JOIN Bellini.Course co ON mc.course_id = co.course_id
    WHERE s.student_id = @StudentId
        AND mc.course_id NOT IN (
            SELECT DISTINCT cl.course_id
            FROM Bellini.Enrollment e
            JOIN Bellini.Class cl ON e.class_id = cl.class_id
            WHERE e.student_id = @StudentId
                AND e.status IN ('ENROLLED', 'COMPLETED')
        )
);
GO

--------------------------------------------------------------------------------
-- 3.8.4: View four-year study plan, semester by semester
-- Function: Bellini.fn_GetStudyPlan
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetStudyPlan (@MajorCode CHAR(5))
RETURNS TABLE
AS
RETURN
(
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
    WHERE sp.major_code = @MajorCode
);
GO

--------------------------------------------------------------------------------
-- 3.8.5: View information of a specific course
-- Function: Bellini.fn_GetCourseDetails
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetCourseDetails (@CourseId CHAR(10))
RETURNS TABLE
AS
RETURN
(
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
    WHERE co.course_id = @CourseId
);
GO

--------------------------------------------------------------------------------
-- 3.8.6: View information of a specific class or all sections of a course
-- Function: Bellini.fn_GetClassOfferings
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetClassOfferings (
    @CourseId CHAR(10) = NULL,
    @Year INT = NULL,
    @Term VARCHAR(20) = NULL
)
RETURNS TABLE
AS
RETURN
(
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
    WHERE (@CourseId IS NULL OR c.course_id = @CourseId)
        AND (@Year IS NULL OR s.year = @Year)
        AND (@Term IS NULL OR s.term = @Term)
);
GO

--------------------------------------------------------------------------------
-- 3.8.7: View information of an instructor or student
-- Function: Bellini.fn_GetPersonDetails
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetPersonDetails (@PersonId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.person_id,
        CONCAT(p.first_name, ' ', p.last_name) AS full_name,
        p.email,
        p.phone,
        p.address,
        CASE 
            WHEN i.instructor_id IS NOT NULL THEN 'Instructor'
            WHEN s.student_id IS NOT NULL THEN 'Student'
            ELSE 'Person'
        END AS person_type,
        s.major_code,
        s.gpa,
        i.office_location
    FROM Bellini.Person p
    LEFT JOIN Bellini.Student s ON p.person_id = s.student_id
    LEFT JOIN Bellini.Instructor i ON p.person_id = i.instructor_id
    WHERE p.person_id = @PersonId
);
GO

--------------------------------------------------------------------------------
-- 3.8.8: Modify Spring 2026 class data
-- Procedures: Bellini.sp_UpdateClassInstructor, Bellini.sp_UpdateClassSchedule, etc.
--------------------------------------------------------------------------------

CREATE OR ALTER PROCEDURE Bellini.sp_UpdateClassInstructor
    @ClassId INT,
    @NewInstructorId INT
AS
BEGIN
    UPDATE Bellini.Class
    SET instructor_id = @NewInstructorId
    WHERE class_id = @ClassId;
END;
GO

CREATE OR ALTER PROCEDURE Bellini.sp_UpdateClassCapacity
    @ClassId INT,
    @NewCapacity INT
AS
BEGIN
    UPDATE Bellini.Class
    SET total_capacity = @NewCapacity
    WHERE class_id = @ClassId;
END;
GO

CREATE OR ALTER PROCEDURE Bellini.sp_UpdateClassSchedule
    @ScheduleId INT,
    @NewDayOfWeek CHAR(3),
    @NewStartTime TIME,
    @NewEndTime TIME,
    @NewLocationId INT
AS
BEGIN
    UPDATE Bellini.ClassSchedule
    SET day_of_week = @NewDayOfWeek,
        start_time = @NewStartTime,
        end_time = @NewEndTime,
        location_id = @NewLocationId
    WHERE schedule_id = @ScheduleId;
END;
GO

--------------------------------------------------------------------------------
-- 3.8.9: List summary of semester and/or accumulated GPA
-- Function: Bellini.fn_GetMajorGPASummary
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetMajorGPASummary (@MajorCode CHAR(5))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        s.major_code,
        m.name AS major_name,
        COUNT(s.student_id) AS total_students,
        AVG(s.gpa) AS average_gpa,
        MAX(s.gpa) AS highest_gpa,
        MIN(s.gpa) AS lowest_gpa,
        COUNT(CASE WHEN s.gpa >= 3.5 THEN 1 END) AS students_above_3_5
    FROM Bellini.Student s
    JOIN Bellini.Major m ON s.major_code = m.major_code
    WHERE s.major_code = @MajorCode
        AND s.gpa IS NOT NULL
    GROUP BY s.major_code, m.name
);
GO

--------------------------------------------------------------------------------
-- 3.8.10: Play what-if scenarios against GPA
-- Function: Bellini.fn_GetWhatIfGPA
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetWhatIfGPA (
    @StudentId INT,
    @ScenarioType VARCHAR(20), -- 'ALL_A', 'ALL_B', 'ONE_FAIL'
    @FailCourseId CHAR(10) = NULL
)
RETURNS TABLE
AS
RETURN
(
    WITH CurrentStatus AS (
        SELECT 
            s.student_id,
            s.earned_hours,
            s.gpa,
            (s.gpa * s.earned_hours) AS current_quality_points
        FROM Bellini.Student s
        WHERE s.student_id = @StudentId
    ),
    EnrolledCourses AS (
        SELECT 
            co.course_id,
            co.credits,
            CASE 
                WHEN @ScenarioType = 'ALL_A' THEN 4.0
                WHEN @ScenarioType = 'ALL_B' THEN 3.0
                WHEN @ScenarioType = 'ONE_FAIL' AND co.course_id = @FailCourseId THEN 0.0
                WHEN @ScenarioType = 'ONE_FAIL' THEN 3.0 -- Assume B for others
                ELSE 0.0
            END AS assumed_grade_points
        FROM Bellini.Enrollment e
        JOIN Bellini.Class c ON e.class_id = c.class_id
        JOIN Bellini.Course co ON c.course_id = co.course_id
        WHERE e.student_id = @StudentId
            AND e.status = 'ENROLLED'
            AND e.grade_letter IS NULL
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
        (cs.current_quality_points + nqp.total_new_quality_points) / (cs.earned_hours + nqp.total_new_credits) AS projected_gpa,
        ((cs.current_quality_points + nqp.total_new_quality_points) / (cs.earned_hours + nqp.total_new_credits)) - cs.gpa AS gpa_change
    FROM CurrentStatus cs
    CROSS JOIN NewQualityPoints nqp
);
GO

--------------------------------------------------------------------------------
-- 3.8.11: View semester transcript or overall transcript
-- Function: Bellini.fn_GetStudentTranscript
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetStudentTranscript (
    @StudentId INT,
    @Year INT = NULL,
    @Term VARCHAR(20) = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        s.student_id,
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
    JOIN Bellini.Enrollment e ON s.student_id = e.student_id
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    WHERE s.student_id = @StudentId
        AND (@Year IS NULL OR sem.year = @Year)
        AND (@Term IS NULL OR sem.term = @Term)
        AND e.status IN ('ENROLLED', 'COMPLETED')
);
GO

--------------------------------------------------------------------------------
-- 3.8.12: Register courses
-- Procedure: Bellini.sp_RegisterStudent
--------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Bellini.sp_RegisterStudent
    @StudentId INT,
    @ClassId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CourseId CHAR(10);
    DECLARE @Credits DECIMAL(3,1);
    DECLARE @SemesterId INT;
    DECLARE @MajorCode CHAR(5);

    -- Get Class/Course Info
    SELECT @CourseId = c.course_id, @Credits = co.credits, @SemesterId = c.semester_id
    FROM Bellini.Class c
    JOIN Bellini.Course co ON c.course_id = co.course_id
    WHERE c.class_id = @ClassId;

    IF @CourseId IS NULL THROW 50001, 'Class does not exist.', 1;

    -- Get Student Info
    SELECT @MajorCode = major_code FROM Bellini.Student WHERE student_id = @StudentId;
    IF @MajorCode IS NULL THROW 50002, 'Student does not exist.', 1;

    -- 1. Check if course is acceptable for major (Required or Elective)
    IF NOT EXISTS (
        SELECT 1 FROM Bellini.MajorCourse WHERE major_code = @MajorCode AND course_id = @CourseId
    )
    BEGIN
        THROW 50003, 'Course is not valid for this student''s major.', 1;
    END

    -- 2. Check for duplicate enrollment
    IF EXISTS (SELECT 1 FROM Bellini.Enrollment WHERE student_id = @StudentId AND class_id = @ClassId)
    BEGIN
        THROW 50004, 'Student is already enrolled in this class.', 1;
    END
    -- Check for same course in same semester (different section)
    IF EXISTS (
        SELECT 1 FROM Bellini.Enrollment e
        JOIN Bellini.Class c ON e.class_id = c.class_id
        WHERE e.student_id = @StudentId AND c.course_id = @CourseId AND c.semester_id = @SemesterId
    )
    BEGIN
        THROW 50005, 'Student is already enrolled in this course for the semester.', 1;
    END

    -- 3. Check Prerequisites
    IF EXISTS (
        SELECT 1
        FROM Bellini.CoursePrerequisite cp
        WHERE cp.course_id = @CourseId
        AND cp.is_corequisite = 0
        AND cp.prereq_id NOT IN (
            -- Courses completed with passing grade
            SELECT c.course_id
            FROM Bellini.Enrollment e
            JOIN Bellini.Class c ON e.class_id = c.class_id
            WHERE e.student_id = @StudentId
            AND e.status = 'COMPLETED'
            AND (e.grade_points >= 2.0 OR e.grade_points IS NULL)
        )
    )
    BEGIN
        THROW 50006, 'Prerequisites not met.', 1;
    END

    -- 4. Check Max Hours (18)
    DECLARE @CurrentHours DECIMAL(5,1);
    SELECT @CurrentHours = ISNULL(SUM(co.credits), 0)
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    WHERE e.student_id = @StudentId AND c.semester_id = @SemesterId AND e.status = 'ENROLLED';

    IF (@CurrentHours + @Credits) > 18
    BEGIN
        THROW 50007, 'Registration would exceed maximum semester hours (18).', 1;
    END

    -- 5. Check Capacity and Status
    DECLARE @Status VARCHAR(20);
    DECLARE @Cap INT;
    DECLARE @Enr INT;
    SELECT @Status = status, @Cap = total_capacity, @Enr = total_enrollment
    FROM Bellini.Class WHERE class_id = @ClassId;

    IF @Status <> 'OPEN' THROW 50008, 'Class is not open.', 1;
    IF @Enr >= @Cap THROW 50009, 'Class is full.', 1;

    -- Proceed
    INSERT INTO Bellini.Enrollment (class_id, student_id, status)
    VALUES (@ClassId, @StudentId, 'ENROLLED');

    -- Update attempted hours
    UPDATE Bellini.Student
    SET attempted_hours = attempted_hours + CAST(@Credits AS INT)
    WHERE student_id = @StudentId;
END;
GO

CREATE OR ALTER FUNCTION Bellini.fn_GetWeeklySchedule (@StudentId INT, @Year INT, @Term VARCHAR(20))
RETURNS TABLE
AS
RETURN
(
    SELECT 
        cs.day_of_week,
        cs.start_time,
        cs.end_time,
        c.course_id,
        co.title,
        c.section,
        CONCAT(l.building, ' ', l.room) AS location
    FROM Bellini.Enrollment e
    JOIN Bellini.Class c ON e.class_id = c.class_id
    JOIN Bellini.Course co ON c.course_id = co.course_id
    JOIN Bellini.Semester sem ON c.semester_id = sem.semester_id
    JOIN Bellini.ClassSchedule cs ON c.class_id = cs.class_id
    LEFT JOIN Bellini.Location l ON cs.location_id = l.location_id
    WHERE e.student_id = @StudentId
        AND sem.year = @Year
        AND sem.term = @Term
        AND e.status = 'ENROLLED'
);
GO

--------------------------------------------------------------------------------
-- 3.8.13: Drop or add a course
-- Procedures: Bellini.sp_DropStudentClass
--------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Bellini.sp_DropStudentClass
    @StudentId INT,
    @ClassId INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CourseId CHAR(10);
    DECLARE @SemesterId INT;

    SELECT @CourseId = c.course_id, @SemesterId = c.semester_id
    FROM Bellini.Class c
    WHERE c.class_id = @ClassId;

    IF @CourseId IS NULL THROW 50010, 'Class not found.', 1;

    -- Check if enrolled
    IF NOT EXISTS (SELECT 1 FROM Bellini.Enrollment WHERE student_id = @StudentId AND class_id = @ClassId AND status = 'ENROLLED')
    BEGIN
        THROW 50011, 'Student is not enrolled in this class.', 1;
    END

    -- Check Corequisites
    -- If this course is a corequisite for ANOTHER enrolled course, cannot drop
    IF EXISTS (
        SELECT 1
        FROM Bellini.Enrollment e
        JOIN Bellini.Class c ON e.class_id = c.class_id
        JOIN Bellini.CoursePrerequisite cp ON c.course_id = cp.course_id
        WHERE e.student_id = @StudentId
        AND e.status = 'ENROLLED'
        AND cp.is_corequisite = 1
        AND cp.prereq_id = @CourseId -- The course being dropped is the prereq/coreq
    )
    BEGIN
        THROW 50012, 'Cannot drop: This course is a corequisite for another enrolled course.', 1;
    END

    -- Proceed
    UPDATE Bellini.Enrollment
    SET status = 'DROPPED'
    WHERE student_id = @StudentId AND class_id = @ClassId;

    -- Decrease attempted hours
    DECLARE @Credits DECIMAL(3,1);
    SELECT @Credits = credits FROM Bellini.Course WHERE course_id = @CourseId;

    UPDATE Bellini.Student
    SET attempted_hours = attempted_hours - CAST(@Credits AS INT)
    WHERE student_id = @StudentId;
END;
GO

--------------------------------------------------------------------------------
-- 3.8.14: Instructors enter or modify grades
-- Procedure: Bellini.sp_EnterGrade
--------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Bellini.sp_EnterGrade
    @InstructorId INT,
    @EnrollmentId INT,
    @GradeLetter VARCHAR(5),
    @GradePoints DECIMAL(4,2)
AS
BEGIN
    -- Audit entry
    INSERT INTO Bellini.GradeEntry (enrollment_id, entered_by, grade_letter, grade_points, comment)
    VALUES (@EnrollmentId, @InstructorId, @GradeLetter, @GradePoints, 'Grade Entry');

    -- Update enrollment
    UPDATE Bellini.Enrollment
    SET grade_letter = @GradeLetter,
        grade_points = @GradePoints,
        status = 'COMPLETED'
    WHERE enrollment_id = @EnrollmentId;
END;
GO

--------------------------------------------------------------------------------
-- 3.8.15: View details of a class including enrollment and roster
-- Function: Bellini.fn_GetClassRoster
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetClassRoster (@ClassId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        e.enrollment_id,
        s.student_id,
        CONCAT(p.first_name, ' ', p.last_name) AS student_name,
        p.email,
        s.major_code,
        e.status,
        e.grade_letter
    FROM Bellini.Enrollment e
    JOIN Bellini.Student s ON e.student_id = s.student_id
    JOIN Bellini.Person p ON s.student_id = p.person_id
    WHERE e.class_id = @ClassId
        AND e.status = 'ENROLLED'
);
GO

--------------------------------------------------------------------------------
-- 3.8.16: List grade summary for Fall 2025 classes
-- Function: Bellini.fn_GetClassGradeStats
--------------------------------------------------------------------------------
CREATE OR ALTER FUNCTION Bellini.fn_GetClassGradeStats (@ClassId INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        c.class_id,
        COUNT(e.enrollment_id) AS total_enrollment,
        AVG(e.grade_points) AS grade_average,
        MAX(e.grade_points) AS highest_grade,
        MIN(e.grade_points) AS lowest_grade,
        COUNT(CASE WHEN e.grade_points >= 3.7 THEN 1 END) AS count_A_range,
        COUNT(CASE WHEN e.grade_points >= 2.7 AND e.grade_points < 3.7 THEN 1 END) AS count_B_range,
        COUNT(CASE WHEN e.grade_points < 2.0 THEN 1 END) AS count_below_C
    FROM Bellini.Class c
    JOIN Bellini.Enrollment e ON c.class_id = e.class_id
    WHERE c.class_id = @ClassId
        AND e.grade_letter IS NOT NULL
    GROUP BY c.class_id
);
GO
