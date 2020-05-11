
/* Нужно используя операторы DDL создать:
1. Создать базу данных.
2. 3-4 основные таблицы для своего проекта.
3. Первичные и внешние ключи для всех созданных таблиц.
4. 1-2 индекса на таблицы.
5. Наложите по одному ограничению в каждой таблице на ввод данных. */

-- Описание и схема проекта здесь: https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project

USE master
GO

DROP DATABASE IF EXISTS TutorsWorkspace
GO

-- 1. Создание базы данных
CREATE DATABASE TutorsWorkspace
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'TutorsWorkspace', FILENAME = N'D:\sqldata\MSSQL14.MSSQLSERVER\MSSQL\DATA\TutorsWorkspace.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'TutorsWorkspace_log', FILENAME = N'D:\sqldata\MSSQL14.MSSQLSERVER\MSSQL\DATA\TutorsWorkspace_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC TutorsWorkspace.dbo.sp_fulltext_database @action = 'enable'
end
GO

ALTER DATABASE TutorsWorkspace SET RECOVERY FULL 
GO

USE TutorsWorkspace
GO

-- 2. Создание схем

create schema Peoples
GO
create schema Learning
GO
create schema Materials
GO
create schema Controls
GO
create schema Sequences
GO

-- 3. Создание последовательностей
CREATE SEQUENCE Sequences.PersonID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.SubjectID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.LessonID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.WorkID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.NoticeID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.ScheduleID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.RatingID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.BookID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.TermID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.TaskID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO

CREATE SEQUENCE Sequences.RatingTypeID 
 AS int
 START WITH 1
 INCREMENT BY 1
 MINVALUE -2147483648
 MAXVALUE 2147483647
 CACHE 
GO
-- 4. Создание таблиц

-- 4.1 Студенты (системно-версионная)
CREATE TABLE Peoples.Students
(
    PersonID int NOT NULL,
 	FullName nvarchar(50) NOT NULL,
	PreferredName nvarchar(50) NOT NULL,

 	ValidFrom datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo datetime2(7) GENERATED ALWAYS AS ROW END NOT NULL
 CONSTRAINT PK_Peoples_Students PRIMARY KEY CLUSTERED (PersonID ASC),
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH (SYSTEM_VERSIONING = ON ( HISTORY_TABLE = Peoples.Students_Archive))
GO

ALTER TABLE Peoples.Students ADD  CONSTRAINT DF_Peoples_Students_PersonID  DEFAULT (NEXT VALUE FOR Sequences.PersonID) FOR PersonID
GO

CREATE NONCLUSTERED INDEX IX_Peoples_Students_FullName ON Peoples.Students(FullName ASC)

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор студента' , @level0type=N'SCHEMA',@level0name=N'Peoples', @level1type=N'TABLE',@level1name=N'Students', @level2type=N'COLUMN',@level2name=N'PersonID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Полное имя студента' , @level0type=N'SCHEMA',@level0name=N'Peoples', @level1type=N'TABLE',@level1name=N'Students', @level2type=N'COLUMN',@level2name=N'FullName'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Студенты' , @level0type=N'SCHEMA',@level0name=N'Peoples', @level1type=N'TABLE',@level1name=N'Students'
GO

-- 4.2 Задания
CREATE TABLE Learning.Tasks
(
    TaskID int NOT NULL,
 	TaskType int NOT NULL, -- 0 - hometask, 1 - control task
	TaskDetails nvarchar(max) NOT NULL,
	TaskWeight int NOT NULL,
 CONSTRAINT PK_Learning_Tasks PRIMARY KEY CLUSTERED (TaskID ASC),
)
GO

ALTER TABLE Learning.Tasks ADD  CONSTRAINT DF_Learning_Tasks_TaskID  DEFAULT (NEXT VALUE FOR Sequences.TaskID) FOR TaskID
GO

ALTER TABLE Learning.Tasks ADD CONSTRAINT CH_Learning_Tasks_TaskType CHECK (TaskType IN (0, 1));
GO

ALTER TABLE Learning.Tasks CHECK CONSTRAINT CH_Learning_Tasks_TaskType
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор задания' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Tasks', @level2type=N'COLUMN',@level2name=N'TaskID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'0 - домашнее задание, 1 - контрольная работа' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Tasks', @level2type=N'COLUMN',@level2name=N'TaskType'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Чем выше вес задания, тем больше оно влияет на итоговую оценку' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Tasks', @level2type=N'COLUMN',@level2name=N'TaskWeight'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Текст задания' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Tasks', @level2type=N'COLUMN',@level2name=N'TaskDetails'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Задания' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Tasks'
GO

-- 4.3. Темы занятий (системно-версионная)
CREATE TABLE Learning.Subjects
(
    SubjectID int NOT NULL,
 	SubjectName nvarchar(100) NOT NULL,
	ControlWorkID int NOT NULL,
 	ValidFrom datetime2(7) GENERATED ALWAYS AS ROW START NOT NULL,
	ValidTo datetime2(7) GENERATED ALWAYS AS ROW END NOT NULL
 CONSTRAINT PK_Learning_Subjects PRIMARY KEY CLUSTERED(SubjectID ASC),
	PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
)
WITH(SYSTEM_VERSIONING = ON ( HISTORY_TABLE = Learning.Subjects_Archive))
GO

ALTER TABLE Learning.Subjects ADD  CONSTRAINT DF_Learning_Subjects_SubjectID  DEFAULT (NEXT VALUE FOR Sequences.SubjectID) FOR SubjectID
GO

ALTER TABLE Learning.Subjects ADD  CONSTRAINT UQ_Learning_Subjects_SubjectName UNIQUE NONCLUSTERED (SubjectName ASC)
GO

ALTER TABLE Learning.Subjects  WITH CHECK ADD CONSTRAINT FK_Learning_Subjects_ControlWorkID_Learning_Tasks FOREIGN KEY(ControlWorkID)
REFERENCES Learning.Tasks (TaskID) 
GO

ALTER TABLE Learning.Subjects CHECK CONSTRAINT FK_Learning_Subjects_ControlWorkID_Learning_Tasks
GO

CREATE NONCLUSTERED INDEX FK_Learning_Subjects_ControlWorkID_Learning_Tasks ON Learning.Subjects(ControlWorkID ASC)

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор темы' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Subjects', @level2type=N'COLUMN',@level2name=N'SubjectID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Наименование темы' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Subjects', @level2type=N'COLUMN',@level2name=N'SubjectName'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор контрольной работы' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Subjects', @level2type=N'COLUMN',@level2name=N'ControlWorkID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Темы занятий' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Subjects'
GO


-- 4.4 Занятия
CREATE TABLE Learning.Lessons
(
    LessonID int NOT NULL,
 	SubjectID int NOT NULL,
 	HomeworkID int NULL,
	LessonName nvarchar(200),
	Literature xml NULL,  
	GlossaryTerms nvarchar(max) NULL

 CONSTRAINT PK_Learning_Lessons PRIMARY KEY CLUSTERED (LessonID ASC)
 )
GO

ALTER TABLE Learning.Lessons ADD CONSTRAINT DF_Learning_Lessons_LessonID  DEFAULT (NEXT VALUE FOR Sequences.LessonID) FOR LessonID
GO

ALTER TABLE Learning.Lessons ADD  CONSTRAINT UQ_Learning_Lessons_LessonName UNIQUE NONCLUSTERED (LessonName ASC)
GO

ALTER TABLE Learning.Lessons  WITH CHECK ADD CONSTRAINT FK_Learning_Lessons_SubjectID_Learning_Subjects FOREIGN KEY(SubjectID)
REFERENCES Learning.Subjects (SubjectID) 
GO

ALTER TABLE Learning.Lessons CHECK CONSTRAINT FK_Learning_Lessons_SubjectID_Learning_Subjects
GO

ALTER TABLE Learning.Lessons  WITH CHECK ADD CONSTRAINT FK_Learning_Lessons_HomeworkID_Learning_Tasks FOREIGN KEY(HomeworkID)
REFERENCES Learning.Tasks (TaskID) 
GO

ALTER TABLE Learning.Lessons CHECK CONSTRAINT FK_Learning_Lessons_HomeworkID_Learning_Tasks
GO

CREATE NONCLUSTERED INDEX FK_Learning_Lessons_SubjectID_Learning_Subjects ON Learning.Lessons(SubjectID ASC);

CREATE NONCLUSTERED INDEX FK_Learning_Lessons_HomeworkID_Learning_Tasks ON Learning.Lessons(HomeworkID ASC);

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор занятия' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'LessonID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор темы занятия' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'SubjectID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор домашнего задания' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'HomeworkID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Наименование урока' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'LessonName'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Список литературы к занятию' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'Literature'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Статьи глоссария к занятию' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons', @level2type=N'COLUMN',@level2name=N'GlossaryTerms'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Занятия' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Lessons'
GO
