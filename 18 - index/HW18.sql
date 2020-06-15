
-- �������. ������ ����� ������� � ��� ����� � ���� � ��������� ��� ��� �������. ���������, ��� ��� ������������ � �������. 

/* � ������ ������� ������� ������� �������� �� �������:
1. ���������������� ������� ������ (� ����������� ������� ��� �� - ��������� �����)
2. ������� ��� ������� ������
3. ������� XML

������� �������� � ����� ������� ��������� �����: 
https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project
� ��� �����, ������� �� �������� ���� ������ � ��������:
https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project/OtusProjectDDL.sql

����� �������:
https://dbdesigner.page.link/EyBwQYZnkuVvwxpg6

� ���������, � ������ ������� ��������� �������:
[PK_Learning_Lessons] - ���������������� ������ ��� ������� �������
[PK_Learning_Subjects] - ���������������� ������ ��� ������� ���
[FK_Learning_Schedules_StudentID_Peoples_Students] - ������� ���� � ������� ���������� ��� ����� �� ����� � �������� ���������
[IX_Peoples_Students_FullName] - ���� �� ������� ����� �������� � ������� ���������
[UQ_Materials_Books_BookID] - ���������������� ������ ��� ������� ����
[PXML_Learning_Lessons_Literature] - ��������� XML-������ � ������� ������� �� ���� ������ ����������

*/

Use TutorsWorkspace

-- �������� ������������� ��� ������ ��������� ���������� � ����������

Drop view if exists Learning.ScheduleInfo;
GO

Create View Learning.ScheduleInfo 
AS
Select 
	Les.LessonName,
	Subj.SubjectName,
	Les.LessonID,
	Subj.SubjectID,
	Sched.LessonDate,
	Sched.StudentID,
	Pupils.FullName AS StudentName
FROM [Learning].[Schedules] AS Sched
INNER JOIN [Learning].[Lessons] AS Les
	ON Sched.LessonID = Les.LessonID
INNER JOIN Peoples.Students AS Pupils
	ON Sched.StudentID = Pupils.PersonID
LEFT JOIN [Learning].[Subjects] AS Subj
	ON Les.SubjectID = Subj.SubjectID
GO

-- 1. ������� ��������� ���������� �� �������� ���������� ��������� �� ������� ��������
Declare @StudentName nvarchar(20);
Set @StudentName = N'��������%';
Select 
				LessonDate, 
				LessonName, 
				StudentName,
				SubjectName
			FROM Learning.ScheduleInfo
			WHERE StudentName Like @StudentName AND LessonDate >= CAST (GETDATE() AS DATE)

/* � ����� ������� IndexSeek1.sqlplan ����� Index Seek �� ��������:

[PK_Learning_Lessons]
[PK_Learning_Subjects]
[FK_Learning_Schedules_StudentID_Peoples_Students]
[IX_Peoples_Students_FullName]
*/

-- 2. ������� ���������� � ���������� �� �������������� ������� �� XML- � JSON-����� ���������� ������:
Declare @LessonID int;
Set @LessonID = 15;
SELECT 
	B.ISBN AS ISBN,
	B.Author AS Author,
	B.BookName AS BookName,
	JSON_VALUE([ExtendedInfo], '$.Publishing') As Publishing,
	JSON_VALUE([ExtendedInfo], '$.PrintRun') As PrintRun,
	T2.Loc.value('@Chapter', 'int') AS Chapter,
	T2.Loc.value('@Paragraph', 'nvarchar(50)') AS Paragraph,
	T2.Loc.value('@Pages', 'nvarchar(20)') AS Pages
	
FROM   [Learning].[Lessons] as l
CROSS APPLY l.[Literature].nodes('/References/Reference') as T2(Loc) 
INNER JOIN Materials.Books As B
	ON T2.Loc.value('@BookID', 'int') = B.BookID
Where l.LessonID = @LessonID

/* � ����� ������� IndexSeek2.sqlplan ����� Index Seek �� ��������:

[PK_Learning_Lessons]
[UQ_Materials_Books_BookID]
[PXML_Learning_Lessons_Literature]

������ �����: ������� ������������.
*/