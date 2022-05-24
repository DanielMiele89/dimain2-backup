CREATE TABLE [Staging].[DirectDebit_AssessmentReason] (
    [ID]                 TINYINT      IDENTITY (1, 1) NOT NULL,
    [Reason_Description] VARCHAR (30) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

