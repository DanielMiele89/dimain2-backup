CREATE TABLE [dbo].[RobocopyOutput] (
    [ID]        INT           IDENTITY (1, 1) NOT NULL,
    [BatchID]   INT           NULL,
    [CommandNo] TINYINT       NULL,
    [Date]      DATETIME      NULL,
    [Line]      VARCHAR (255) NULL
);

