
-- Описание и файлы проекта: https://github.com/sburovsky/-otus-mssql-2020-02-burovsky/tree/master/Project
-- Схема проекта: https://dbdesigner.page.link/EyBwQYZnkuVvwxpg6

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

CREATE XML SCHEMA COLLECTION Materials.LiteratureXmlSchema AS   
N' <xsd:schema xmlns:xsd="http://www.w3.org/2001/XMLSchema"
			 xmlns:sqltypes="http://schemas.microsoft.com/sqlserver/2004/sqltypes" 
			 elementFormDefault="qualified">
    <xsd:import namespace="http://schemas.microsoft.com/sqlserver/2004/sqltypes" schemaLocation="http://schemas.microsoft.com/sqlserver/2004/sqltypes/sqltypes.xsd" />
    <xsd:element name="References">
		<xsd:complexType>  
            <xsd:sequence maxOccurs="unbounded">  
              <xsd:element name="Reference"> 
			  	<xsd:complexType>
					<xsd:attribute name="BookID" type="sqltypes:int" use="required" />
					<xsd:attribute name="Chapter" type="sqltypes:int" use="optional" />
					<xsd:attribute name="Paragraph" use="optional">
						<xsd:simpleType>
							<xsd:restriction base="sqltypes:nvarchar" sqltypes:sqlCompareOptions="IgnoreCase IgnoreWidth">
								<xsd:maxLength value="50" />
							</xsd:restriction>
						</xsd:simpleType>
					</xsd:attribute>
					<xsd:attribute name="Pages" use="optional">
						<xsd:simpleType>
							<xsd:restriction base="sqltypes:nvarchar" sqltypes:sqlCompareOptions="IgnoreCase IgnoreWidth">
								<xsd:maxLength value="20" />
							</xsd:restriction>
						</xsd:simpleType>
					</xsd:attribute>
				</xsd:complexType>
			  </xsd:element>
			</xsd:sequence>
		  </xsd:complexType>
	</xsd:element>
  </xsd:schema>'
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

-- 4.3 Темы занятий (системно-версионная)
CREATE TABLE Learning.Subjects
(
    SubjectID int NOT NULL,
 	SubjectName nvarchar(100) NOT NULL,
	ControlWorkID int NULL,
	SubjectHours int NOT NULL,
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

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Количество часов на изучение темы' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Subjects', @level2type=N'COLUMN',@level2name=N'SubjectHours'
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
	Literature xml(Materials.LiteratureXmlSchema) NULL,  
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

CREATE PRIMARY XML INDEX [PXML_Learning_Lessons_Literature]
ON Learning.Lessons (Literature)
GO

CREATE XML INDEX [SXML_Learning_Lessons_Literature_Path]
ON Learning.Lessons (Literature)
USING XML INDEX [PXML_Learning_Lessons_Literature] 
FOR PATH
GO

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

-- 4.5 расписание занятий
CREATE TABLE Learning.Schedules (
	UnitID int NOT NULL,
	StudentID int NOT NULL,
	LessonID int NOT NULL,
	LessonDate date NOT NULL,
	HomeWorkStatus int NOT NULL, 
  CONSTRAINT PK_LEARNING_SCHEDULES PRIMARY KEY CLUSTERED
  (
  UnitID ASC
  ) 
)
GO

ALTER TABLE Learning.Schedules ADD CONSTRAINT DF_Learning_Schedules_UnitID  DEFAULT (NEXT VALUE FOR Sequences.ScheduleID) FOR UnitID
GO

ALTER TABLE Learning.Schedules WITH CHECK ADD CONSTRAINT FK_Learning_Schedules_StudentID_Peoples_Students FOREIGN KEY (StudentID) REFERENCES Peoples.Students(PersonID)

GO

ALTER TABLE Learning.Schedules CHECK CONSTRAINT FK_Learning_Schedules_StudentID_Peoples_Students
GO

ALTER TABLE Learning.Schedules WITH CHECK ADD CONSTRAINT FK_Learning_Schedules_LessonID_Learning_Lessons FOREIGN KEY (LessonID) REFERENCES Learning.Lessons(LessonID)

GO

ALTER TABLE Learning.Schedules CHECK CONSTRAINT FK_Learning_Schedules_LessonID_Learning_Lessons
GO

ALTER TABLE Learning.Schedules ADD CONSTRAINT CH_Learning_Schedules_HomeWorkStatus CHECK (HomeWorkStatus >=0 AND HomeWorkStatus <=4); 
GO

ALTER TABLE Learning.Schedules CHECK CONSTRAINT CH_Learning_Schedules_HomeWorkStatus
GO

ALTER TABLE Learning.Schedules ADD CONSTRAINT DF_Learning_Schedules_HomeWorkStatus  DEFAULT 0 FOR HomeWorkStatus
GO

CREATE NONCLUSTERED INDEX FK_Learning_Schedules_StudentID_Peoples_Students ON Learning.Schedules(StudentID ASC);

CREATE NONCLUSTERED INDEX FK_Learning_Schedules_LessonID_Learning_Lessons ON Learning.Schedules(LessonID ASC);

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор элемента расписания' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules', @level2type=N'COLUMN',@level2name=N'UnitID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор студента' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules', @level2type=N'COLUMN',@level2name=N'StudentID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор занятия' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules', @level2type=N'COLUMN',@level2name=N'LessonID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Дата занятия' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules', @level2type=N'COLUMN',@level2name=N'LessonDate'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Статус домашней работы: 0 - не выдана, 1 - выдана, 2 - на проверке, 3 - выполнена' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules', @level2type=N'COLUMN',@level2name=N'HomeWorkStatus'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Расписание занятий' , @level0type=N'SCHEMA',@level0name=N'Learning', @level1type=N'TABLE',@level1name=N'Schedules'
GO

-- 4.6 литература
CREATE TABLE Materials.Books (
	BookID int NOT NULL,
	ISBN nvarchar(13) NOT NULL,
	Author nvarchar(200) NOT NULL,
	BookName nvarchar(max) NOT NULL,
	ExtendedInfo nvarchar(max),
  CONSTRAINT PK_MATERIALS_BOOKS PRIMARY KEY NONCLUSTERED
  (
  ISBN ASC
  )
)
GO

ALTER TABLE Materials.Books ADD CONSTRAINT DF_Materials_Books_BookID  DEFAULT (NEXT VALUE FOR Sequences.BookID) FOR BookID
GO

ALTER TABLE Materials.Books ADD CONSTRAINT UQ_Materials_Books_BookID UNIQUE CLUSTERED (BookID ASC)
GO

ALTER TABLE Materials.Books ADD CONSTRAINT CH_Materials_Books_ISBN CHECK (LEN(ISBN) IN (9, 10, 13) AND ISBN NOT LIKE '%[^0-9]%'); -- формат ISBN 9, 10 или 13 цифр
GO

ALTER TABLE Materials.Books CHECK CONSTRAINT CH_Materials_Books_ISBN
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор книги' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books', @level2type=N'COLUMN',@level2name=N'BookID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Код ISBN' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books', @level2type=N'COLUMN',@level2name=N'ISBN'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Автор книги' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books', @level2type=N'COLUMN',@level2name=N'Author'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Наименование книги' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books', @level2type=N'COLUMN',@level2name=N'BookName'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Дополнительная информация JSON (издательство, количество страниц и пр.)' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books', @level2type=N'COLUMN',@level2name=N'ExtendedInfo'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Литература' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Books'
GO

-- 4.7 глоссарий

CREATE TABLE Materials.Glossary (
	TermID int NOT NULL,
	Term nvarchar(200) NOT NULL,
	TermDescription nvarchar(max) NOT NULL,
  CONSTRAINT PK_MATERIALS_GLOSSARY PRIMARY KEY CLUSTERED
  (
  TermID ASC
  )) 
GO

ALTER TABLE Materials.Glossary ADD CONSTRAINT DF_Materials_Glossary_TermID  DEFAULT (NEXT VALUE FOR Sequences.TermID) FOR TermID
GO

ALTER TABLE Materials.Glossary ADD CONSTRAINT UQ_Materials_Glossary_Term UNIQUE NONCLUSTERED (Term ASC)
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор статьи' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Glossary', @level2type=N'COLUMN',@level2name=N'TermID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Термин' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Glossary', @level2type=N'COLUMN',@level2name=N'Term'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Описание термина' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Glossary', @level2type=N'COLUMN',@level2name=N'TermDescription'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Глоссарий' , @level0type=N'SCHEMA',@level0name=N'Materials', @level1type=N'TABLE',@level1name=N'Glossary'
GO

-- 4.8 обратная связь
CREATE TABLE Controls.Feedback (
	NoteID int NOT NULL,
	StudentID int NOT NULL,
	SubjectID int NOT NULL,
	Note nvarchar(max) NOT NULL,
  CONSTRAINT PK_CONTROLS_FEEDBACK PRIMARY KEY CLUSTERED
  (
  NoteID ASC
  ))
GO

ALTER TABLE Controls.Feedback ADD CONSTRAINT DF_Controls_Feedback_NoteID  DEFAULT (NEXT VALUE FOR Sequences.NoticeID) FOR NoteID
GO

ALTER TABLE Controls.Feedback WITH CHECK ADD CONSTRAINT FK_Controls_Feedback_StudentID_Peoples_Students FOREIGN KEY (StudentID) REFERENCES Peoples.Students(PersonID)
GO

ALTER TABLE Controls.Feedback CHECK CONSTRAINT FK_Controls_Feedback_StudentID_Peoples_Students
GO

ALTER TABLE Controls.Feedback WITH CHECK ADD CONSTRAINT FK_Controls_Feedback_SubjectID_Learning_Subjects FOREIGN KEY (SubjectID) REFERENCES Learning.Subjects(SubjectID)
GO

ALTER TABLE Controls.Feedback CHECK CONSTRAINT FK_Controls_Feedback_SubjectID_Learning_Subjects
GO

CREATE NONCLUSTERED INDEX FK_Controls_Feedback_SubjectID_Learning_Subjects ON Controls.Feedback(SubjectID ASC);

CREATE NONCLUSTERED INDEX FK_Controls_Feedback_StudentID_Peoples_Students ON Controls.Feedback(StudentID ASC);


EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор замечания' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Feedback', @level2type=N'COLUMN',@level2name=N'NoteID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор студента' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Feedback', @level2type=N'COLUMN',@level2name=N'StudentID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор темы' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Feedback', @level2type=N'COLUMN',@level2name=N'SubjectID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Замечание' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Feedback', @level2type=N'COLUMN',@level2name=N'Note'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Обратная связь' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Feedback'
GO

-- 4.9 контрольные работы
CREATE TABLE Controls.ControlWork (
	WorkID bigint NOT NULL,
	StudentID int NOT NULL,
	TaskID int NOT NULL,
	Mark int NOT NULL,
	WorkDate date NOT NULL,
  CONSTRAINT PK_CONTROLS_CONTROLWORK PRIMARY KEY CLUSTERED
  (
  WorkID ASC
  ) 
)
GO

ALTER TABLE Controls.ControlWork ADD CONSTRAINT DF_Controls_ControlWork_WorkID  DEFAULT (NEXT VALUE FOR Sequences.WorkID) FOR WorkID
GO

ALTER TABLE Controls.ControlWork WITH CHECK ADD CONSTRAINT FK_Controls_ControlWork_StudentID_Peoples_Students FOREIGN KEY (StudentID) REFERENCES Peoples.Students(PersonID)
GO

ALTER TABLE Controls.ControlWork CHECK CONSTRAINT FK_Controls_ControlWork_StudentID_Peoples_Students
GO

ALTER TABLE Controls.ControlWork WITH CHECK ADD CONSTRAINT FK_Controls_ControlWork_TaskID_Learning_Tasks FOREIGN KEY (TaskID) REFERENCES Learning.Tasks(TaskID)
GO

ALTER TABLE Controls.ControlWork CHECK CONSTRAINT FK_Controls_ControlWork_TaskID_Learning_Tasks
GO

CREATE NONCLUSTERED INDEX FK_Controls_ControlWork_StudentID_Peoples_Students ON Controls.ControlWork(StudentID ASC);

CREATE NONCLUSTERED INDEX FK_Controls_ControlWork_TaskID_Learning_Tasks ON Controls.ControlWork(TaskID ASC);

ALTER TABLE Controls.ControlWork ADD CONSTRAINT CH_Controls_ControlWork_Mark CHECK (Mark > 0 AND Mark <= 10 ); -- оценка от 1 до 10
GO

ALTER TABLE Controls.ControlWork CHECK CONSTRAINT CH_Controls_ControlWork_Mark
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор работы' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork', @level2type=N'COLUMN',@level2name=N'WorkID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор студента' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork', @level2type=N'COLUMN',@level2name=N'StudentID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор задания' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork', @level2type=N'COLUMN',@level2name=N'TaskID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Оценка' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork', @level2type=N'COLUMN',@level2name=N'Mark'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Дата работы' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork', @level2type=N'COLUMN',@level2name=N'WorkDate'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Контрольные работы' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'ControlWork'
GO

-- 4.10 типы рейтингов
CREATE TABLE Controls.RatingTypes (
	RatingTypeID int NOT NULL,
	RatingName nvarchar(100) NOT NULL,
	RatingDescription nvarchar(max) NOT NULL,
  CONSTRAINT PK_CONTROLS_RATINGTYPES PRIMARY KEY CLUSTERED
  (
  RatingTypeID ASC
  )  
)
GO

ALTER TABLE Controls.RatingTypes ADD CONSTRAINT DF_Controls_RatingTypes_RatingTypeID  DEFAULT (NEXT VALUE FOR Sequences.RatingTypeID) FOR RatingTypeID
GO

ALTER TABLE  Controls.RatingTypes  ADD CONSTRAINT UQ_Controls_RatingTypes_RatingName UNIQUE NONCLUSTERED (RatingName ASC)
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор типа рейтинга' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'RatingTypes', @level2type=N'COLUMN',@level2name=N'RatingTypeID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Наименование рейтинга' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'RatingTypes', @level2type=N'COLUMN',@level2name=N'RatingName'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Описание рейтинга' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'RatingTypes', @level2type=N'COLUMN',@level2name=N'RatingDescription'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Типы рейтингов' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'RatingTypes'
GO

-- 4.11 рейтинги
CREATE TABLE Controls.Ratings (
	RatingID int NOT NULL,
	StudentID int NOT NULL,
	RatingTypeID int NOT NULL,
	Rating decimal(10,2),
  CONSTRAINT PK_CONTROLS_RATINGS PRIMARY KEY CLUSTERED
  (
  RatingID ASC
  )  
)
GO

ALTER TABLE Controls.Ratings ADD CONSTRAINT DF_Controls_Ratings_RatingID  DEFAULT (NEXT VALUE FOR Sequences.RatingID) FOR RatingID
GO

ALTER TABLE Controls.Ratings WITH CHECK ADD CONSTRAINT FK_Controls_Ratings_StudentID_Peoples_Students FOREIGN KEY (StudentID) REFERENCES Peoples.Students(PersonID)
GO

ALTER TABLE Controls.Ratings CHECK CONSTRAINT FK_Controls_Ratings_StudentID_Peoples_Students
GO

ALTER TABLE Controls.Ratings WITH CHECK ADD CONSTRAINT FK_Controls_Ratings_RatingTypeID_Controls_RatingTypes FOREIGN KEY (RatingTypeID) REFERENCES Controls.RatingTypes(RatingTypeID)
GO

ALTER TABLE Controls.Ratings CHECK CONSTRAINT FK_Controls_Ratings_RatingTypeID_Controls_RatingTypes
GO

CREATE NONCLUSTERED INDEX FK_Controls_Ratings_RatingTypeID_Controls_RatingTypes ON Controls.Ratings(RatingTypeID ASC);

CREATE NONCLUSTERED INDEX FK_Controls_Ratings_StudentID_Peoples_Students ON Controls.Ratings(StudentID ASC);

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Уникальный идентификатор рейтинга' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Ratings', @level2type=N'COLUMN',@level2name=N'RatingID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентификатор студента' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Ratings', @level2type=N'COLUMN',@level2name=N'StudentID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Идентиифкатор типа рейтинга' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Ratings', @level2type=N'COLUMN',@level2name=N'RatingTypeID'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Рейтинг по соответствующей типу рейтинга методике' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Ratings', @level2type=N'COLUMN',@level2name=N'Rating'
GO

EXEC sys.sp_addextendedproperty @name=N'Description', @value=N'Рейтинги' , @level0type=N'SCHEMA',@level0name=N'Controls', @level1type=N'TABLE',@level1name=N'Ratings'
GO

