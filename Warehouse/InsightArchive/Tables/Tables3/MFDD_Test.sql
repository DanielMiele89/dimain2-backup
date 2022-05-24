CREATE TABLE [InsightArchive].[MFDD_Test] (
    [ID]            INT          IDENTITY (1, 1) NOT NULL,
    [SourceUID]     VARCHAR (20) NOT NULL,
    [BankAccountID] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

