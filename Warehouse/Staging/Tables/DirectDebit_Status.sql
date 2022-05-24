CREATE TABLE [Staging].[DirectDebit_Status] (
    [ID]                 TINYINT      IDENTITY (1, 1) NOT NULL,
    [Status_Description] VARCHAR (30) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

