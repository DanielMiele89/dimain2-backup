CREATE TABLE [MI].[LoginInfo] (
    [ID]               INT           IDENTITY (1, 1) NOT NULL,
    [FanID]            INT           NOT NULL,
    [Gender]           CHAR (1)      NULL,
    [Age]              INT           NULL,
    [PostCode]         VARCHAR (10)  NULL,
    [PostCodeDistrict] VARCHAR (4)   NULL,
    [LoginDate]        DATE          NULL,
    [TimeDesc]         VARCHAR (50)  NULL,
    [BookType]         VARCHAR (50)  NOT NULL,
    [AccountType]      VARCHAR (300) NULL,
    [LoginWeekDay]     NVARCHAR (30) NULL,
    CONSTRAINT [PK_MI_LoginInfo] PRIMARY KEY CLUSTERED ([ID] ASC)
);

