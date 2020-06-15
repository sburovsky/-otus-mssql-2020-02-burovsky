
-- «адание. ƒумаем какие запросы у вас будут в базе и добавл€ем дл€ них индексы. ѕровер€ем, что они используютс€ в запросе. 

/* ¬ рамках данного задани€ обратим внимание на индексы:
1.  ластеризованные индексы таблиц (в большинстве случаев они же - первичные ключи)
2. »ндексы дл€ внешних ключей
3. »ндексы XML

 раткое описание и файлы проекта наход€тс€ здесь: 
https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project
в том числе, скрипты по созданию всех таблиц и индексов:
https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project/OtusProjectDDL.sql

—хема проекта:
https://dbdesigner.page.link/EyBwQYZnkuVvwxpg6

¬ частности, в рамках проекта добавлены индексы:
[PK_Learning_Lessons] - кластеризованный индекс дл€ таблицы зан€тий
[PK_Learning_Subjects] - кластеризованный индекс дл€ таблицы тем
[FK_Learning_Schedules_StudentID_Peoples_Students] - внешний ключ в таблице расписаний дл€ св€зи по ключу с таблицей студентов
[IX_Peoples_Students_FullName] - ключ по полному имени студента в таблице студентов
[UQ_Materials_Books_BookID] - кластеризованный индекс дл€ таблицы книг
[PXML_Learning_Lessons_Literature] - первичный XML-индекс в таблице зан€тий по полю списка литературы

*/

Use TutorsWorkspace

-- —оздадим представление дл€ вывода подробной информации о расписании

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

-- 1. получим подробную информацию по текущему расписанию студентов по фамилии Ќекрасов
Declare @StudentName nvarchar(20);
Set @StudentName = N'Ќекрасов%';
Select 
				LessonDate, 
				LessonName, 
				StudentName,
				SubjectName
			FROM Learning.ScheduleInfo
			WHERE StudentName Like @StudentName AND LessonDate >= CAST (GETDATE() AS DATE)

/* в плане запроса IndexSeek1.sqlplan видим Index Seek по индексам:

[PK_Learning_Lessons]
[PK_Learning_Subjects]
[FK_Learning_Schedules_StudentID_Peoples_Students]
[IX_Peoples_Students_FullName]
*/

-- 2. ѕолучим информацию о литературе по идентификатору зан€ти€ из XML- и JSON-полей нескольких таблиц:
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

/* в плане запроса IndexSeek2.sqlplan видим Index Seek по индексам:

[PK_Learning_Lessons]
[UQ_Materials_Books_BookID]
[PXML_Learning_Lessons_Literature]

ƒелаем вывод: индексы используютс€.
*/