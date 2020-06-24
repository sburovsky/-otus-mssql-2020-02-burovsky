
USE TutorsWorkspace;

DROP FUNCTION IF EXISTS Sales.MaxTransactionCustomer;
GO

Drop view if exists Learning.LessonDetails;
GO

Create View Learning.LessonDetails 
AS
Select 
	Les.LessonID,
	Subj.SubjectID,
	Les.LessonName,
	Subj.SubjectName,
	HomeWork.TaskDetails AS HomeWorkDetails,
	ControlWork.TaskDetails AS ControlWorkDetails
FROM [Learning].[Lessons] AS Les
LEFT JOIN [Learning].[Subjects] AS Subj
	ON Les.SubjectID = Subj.SubjectID
LEFT JOIN [Learning].[Tasks] AS HomeWork
	ON HomeWork.TaskType = 0 AND Les.HomeworkID = HomeWork.TaskID
LEFT JOIN [Learning].[Tasks] AS ControlWork
	ON ControlWork.TaskType = 1 AND Subj.ControlWorkID = ControlWork.TaskID
GO

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

Drop Function if exists Learning.SchedulesByStudent;
GO

CREATE FUNCTION Learning.SchedulesByStudent(@StudentName nvarchar(30)) 
RETURNS TABLE 

-- расписание студента за период
AS 
	Return
			(Select 
				LessonDate, 
				LessonName, 
				StudentName,
				SubjectName
			FROM Learning.ScheduleInfo
			WHERE StudentName Like @StudentName AND LessonDate >= CAST (GETDATE() AS DATE)
			);
GO

Drop Function if exists Learning.LessonBySubject;
GO

CREATE FUNCTION Learning.LessonBySubject(@Name nvarchar(20)) 
RETURNS TABLE 

-- поиск занятий

AS 
	Return
			(Select 
				SubjectName,
				LessonName, 
				[ControlWorkDetails], 
				[HomeWorkDetails]
			FROM [Learning].[LessonDetails] 
			WHERE SubjectName Like @Name OR LessonName Like @Name)
GO


Drop Function if exists Learning.ActualScheduleByStudent;
GO

CREATE Function Learning.ActualScheduleByStudent(@StudentName nvarchar(20))
RETURNS TABLE 

-- ближайшие занятия
		AS 
			Return  
		Select 				
			StudentName,
			StudentID,
			LessonDate, 
			LessonName, 
			SubjectName
		 FROM (Select
						StudentID,
						LessonDate, 
						LessonName, 
						StudentName,
						SubjectName,
						RANK() OVER (PARTITION BY StudentID ORDER BY LessonDate ASC) as RankDate 
					FROM Learning.ScheduleInfo
					WHERE LessonDate >=  CAST(GETDATE() AS DATE) AND StudentName like @StudentName) AS ScheduleWithRanks
		WHERE RankDate = 1 

GO

Drop Function if exists Learning.BackLogByStudent;
GO

CREATE Function Learning.BackLogByStudent(@StudentID int)
RETURNS TABLE 

-- задолженность по домашним заданиям
AS 
	Return
	(
	Select Tasks.TaskDetails,
	Sched.LessonDate AS WorkDate

	FROM [Learning].[Schedules] AS Sched
		INNER JOIN [Learning].[Lessons] AS Les
	ON Sched.LessonID = Les.LessonID
	INNER JOIN [Learning].[Tasks] AS Tasks
		ON Les.HomeworkID = Tasks.TaskID
	WHERE [StudentID] = @StudentID AND Sched.HomeWorkStatus = 1 -- выдана
	)

	
GO

Drop PROC if exists Learning.TableOfProgress;
GO

CREATE PROC Learning.TableOfProgress
-- результаты контрольных работ 
AS 

DECLARE @command NVARCHAR(max)
DECLARE @IDs NVARCHAR(max)

SELECT @IDs = STUFF(( SELECT DISTINCT '],[' + Subj.SubjectName FROM [Controls].[ControlWork] as CtrlWrk
	INNER JOIN [Learning].[Subjects] AS Subj
		ON CtrlWrk.[TaskID] = Subj.[ControlWorkID]
		FOR XML PATH('') ),1,2,'') + ']';

SET @command =
'SELECT 
	StudentName AS StudentName,' + @IDs + '
FROM 
	(
	Select 
		Pupils.FullName AS StudentName,
		Subj.SubjectName,
		ISNULL(CtrlWrk.Mark, 0) AS Mark
	FROM [Controls].[ControlWork] as CtrlWrk
	INNER JOIN [Peoples].[Students] AS Pupils
		ON CtrlWrk.StudentID = Pupils.PersonID
	INNER JOIN [Learning].[Subjects] AS Subj
		ON CtrlWrk.[TaskID] = Subj.[ControlWorkID]
	WHERE CtrlWrk.Mark > 0
	) AS Progress
PIVOT (MAX(Mark)
FOR Progress.SubjectName IN (' + @IDs +'))
as PVT
ORDER BY StudentName';

EXEC (@command);

Return
GO

Drop Function if exists Learning.ScheduleByTerm;
GO

CREATE Function Learning.ScheduleByTerm(@StudentID int, @Term nvarchar(50))
RETURNS TABLE 

-- расписание занятий по глоссарию
AS 
	Return
	(
		Select 
			less.[LessonName],
			SI.LessonDate,
			SI.StudentName,
			SI.SubjectName
		FROM [Learning].[Lessons] AS less	
			CROSS APPLY OPENJSON(less.[GlossaryTerms], '$.Terms') js
		INNER JOIN [Materials].[Glossary] as Gls
			ON js.value = Gls.TermID
		INNER JOIN [Learning].[ScheduleInfo] SI ON
			less.LessonID = SI.LessonID
		Where Gls.Term = @Term AND SI.StudentID = @StudentID
		)

Drop Function if exists Learning.GlossaryByLesson;
GO

CREATE Function Learning.GlossaryByLesson(@LessonID int)
RETURNS TABLE 

-- термины по занятию
AS 
	Return
	(
		Select 
			less.[LessonName],
			Gls.Term,
			Gls.TermDescription
		FROM [Learning].[Lessons] AS less	
			CROSS APPLY OPENJSON(less.[GlossaryTerms], '$.Terms') js
		INNER JOIN [Materials].[Glossary] as Gls
			ON js.value = Gls.TermID
		Where less.LessonID = @LessonID
		)
GO

Drop Function if exists Learning.LiteratureByLesson;
GO

CREATE Function Learning.LiteratureByLesson(@LessonID int)
RETURNS TABLE 

-- Литература по занятию
AS 
	Return
	(
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
Where l.LessonID = @LessonID)

GO

Drop Proc if exists Controls.FeedbackAdd;
GO

CREATE Proc Controls.FeedbackAdd
(
@StudentID int, 
@SubjectID int, 
@Note nvarchar(max)
)
WITH EXECUTE AS CALLER  
AS  
    SET NOCOUNT ON;

	if @Note is null OR @Note = ''
	BEGIN  
		PRINT N'ERROR: Отзыв не может быть пустым.'  
		RETURN  
    end;

	IF NOT EXISTS (SELECT TOP (1) 1 FROM Peoples.Students AS Pupils where Pupils.PersonID = @StudentID)
	BEGIN  
		PRINT N'ERROR: Не найден идентификатор студента.'  
		RETURN  
	END 
	IF NOT EXISTS (SELECT TOP (1) 1 FROM Learning.Subjects AS Subj where Subj.SubjectID = @SubjectID)
	BEGIN  
		PRINT N'ERROR: Не найден идентификатор темы.'  
		RETURN  
	END; 

	INSERT INTO [Controls].[Feedback]
		([NoteID], [StudentID], [SubjectID], [Note])
	VALUES (default, @StudentID, @SubjectID, @Note);
	PRINT N'Отзыв отправлен. За вами уже выехали'
GO


Drop Proc if exists Controls.MarkAdd;
GO

CREATE Proc Controls.MarkAdd
(
@StudentID int, 
@SubjectID int, 
@Mark int,
@WorkDate date
)
WITH EXECUTE AS CALLER  
AS  
    SET NOCOUNT ON;
	
	if @Mark is null OR @Mark < 1 OR @Mark > 10
	BEGIN  
		PRINT N'ERROR: Укажите оценку в диапазоне от 1 до 10'  
		RETURN  
    end;

	if @WorkDate is null 
	BEGIN  
		PRINT N'ERROR: Не указана дата выполнения работы.'  
		RETURN  
    end;

	IF NOT EXISTS (SELECT TOP (1) 1 FROM Peoples.Students AS Pupils where Pupils.PersonID = @StudentID)
	BEGIN  
		PRINT N'ERROR: Не найден идентификатор студента.'  
		RETURN  
	END
	
	Declare @TaskID int;
	SET @TaskID = (
		SELECT TOP (1) 
			Subj.ControlWorkID
		FROM Learning.Subjects AS Subj 
		where Subj.SubjectID = @SubjectID 
			AND 1 IN (Select 1 
						FROM Learning.Tasks AS Ts 
						Where Ts.TaskType = 1 AND Subj.ControlWorkID = Ts.TaskID))

	if @TaskID is null 
	BEGIN  
		PRINT N'ERROR: Не найдено контрольное задание по теме.'  
		RETURN  
    end;

	MERGE [Controls].[ControlWork] AS target 
	USING (Values (@StudentID, @SubjectID, @Mark, @Workdate)) 
		AS source (StudentID, [TaskID], Mark, Workdate) 
		ON
	 (target.StudentID = source.StudentID AND target.TaskID = source.TaskID) 
	WHEN MATCHED 
		THEN UPDATE SET Mark = source.Mark,
						Workdate = source.Workdate
	WHEN NOT MATCHED 
		THEN INSERT (WorkID, StudentID, TaskID, Mark, Workdate) 
			VALUES (default, source.StudentID, source.TaskID, source.Mark, source.Workdate) 
	OUTPUT case 
			When $action = 'UPDATE' 
				THEN N'Оценка обновлена'
			When $action = 'INSERT'
				THEN N'Оценка добавлена'
			END;
GO

Drop Function if exists Learning.RatingCount;
GO

CREATE Function Learning.RatingCount(@StudentID int)
RETURNS TABLE 

-- расчет рейтингов студента
AS 
	Return
	(

		WITH cteMarks AS 
		( SELECT 
			cast (ctrlw.mark as decimal(10, 1)) AS Mark,
			ctrlw.StudentID,
			ts.TaskWeight	
		FROM Controls.ControlWork as ctrlw
			INNER JOIN Learning.Tasks AS ts
				on ctrlw.TaskID = ts.TaskID AND ts.TaskType = 1
		Where  ctrlw.StudentID = @StudentID AND
			 ctrlw.mark is not null 
			AND ctrlw.mark > 0)
		SELECT DISTINCT
			M.StudentID AS StudentID,
			AVG(M.mark) OVER (PARTITION BY M.StudentID) AS GPA,
			SUM(M.mark * M.TaskWeight) OVER (PARTITION BY M.StudentID) / 
				CASE WHEN SUM(M.TaskWeight) OVER (PARTITION BY M.StudentID)  = 0 THEN 0 
						ELSE SUM (M.TaskWeight) OVER (PARTITION BY M.StudentID)
				END AS GPWA,
			1 + 3 * (10 - AVG(M.mark) OVER (PARTITION BY M.StudentID)) / 5 AS GPA_Germany,
			CAST(PERCENTILE_CONT(0.5) WITHIN GROUP ( ORDER BY M.mark) OVER (Partition BY StudentID)  AS decimal(10,2)) AS Median_Mark,
			CAST(PERCENTILE_DISC(0.5) WITHIN GROUP ( ORDER BY M.mark) OVER (Partition BY StudentID) AS decimal(10,2)) AS Median_Discrete_Mark
		FROM cteMarks AS M);
