CREATE TABLE [Staging].[DirectDebit_Categories_Internal] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [Category1] VARCHAR (30) NOT NULL,
    [Category2] VARCHAR (30) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

