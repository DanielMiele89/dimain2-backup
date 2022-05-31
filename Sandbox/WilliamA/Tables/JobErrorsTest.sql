CREATE TABLE [WilliamA].[JobErrorsTest] (
    [JobID]        UNIQUEIDENTIFIER NOT NULL,
    [JobName]      [sysname]        NOT NULL,
    [Step]         INT              NOT NULL,
    [StepName]     [sysname]        NOT NULL,
    [RunDate]      DATE             NULL,
    [RunTime]      VARCHAR (18)     NULL,
    [sql_severity] INT              NOT NULL,
    [Message]      NVARCHAR (4000)  NULL,
    [server]       [sysname]        NOT NULL
);

