CREATE TABLE [InsightArchive].[logininfo] (
    [Gender]           CHAR (1)      NULL,
    [Age]              INT           NULL,
    [PostCode]         VARCHAR (10)  NULL,
    [PostCodeDistrict] VARCHAR (4)   NULL,
    [LoginDate]        DATE          NULL,
    [TimeDesc]         VARCHAR (50)  NULL,
    [BookType]         VARCHAR (50)  NOT NULL,
    [AccountType]      VARCHAR (203) NULL,
    [LoginWeekDay]     NVARCHAR (30) NULL
);

