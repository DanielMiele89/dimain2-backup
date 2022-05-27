CREATE TABLE [Staging].[R0103_DirectDebitExceptions] (
    [ClubID]            INT           NULL,
    [CIN]               VARCHAR (20)  NULL,
    [FanID]             INT           NOT NULL,
    [TransactionDate]   DATE          NOT NULL,
    [OIN]               INT           NOT NULL,
    [Narrative]         NVARCHAR (18) NOT NULL,
    [TransactionAmount] MONEY         NOT NULL
);

