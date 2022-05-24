CREATE TABLE [Monitor].[ErrorLog] (
    [ID]            INT           IDENTITY (1, 1) NOT NULL,
    [ErrorDate]     DATETIME      NULL,
    [ProcedureName] VARCHAR (100) NULL,
    [ErrorLine]     INT           NULL,
    [ErrorMessage]  VARCHAR (200) NULL,
    [ErrorNumber]   INT           NULL,
    [ErrorSeverity] INT           NULL,
    [ErrorState]    INT           NULL
);

