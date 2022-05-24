CREATE TABLE [Relational].[RedemptionCode_DigitalCodes] (
    [ID]          INT           IDENTITY (1, 1) NOT NULL,
    [DigitalCode] VARCHAR (100) NOT NULL,
    [BatchID]     INT           NOT NULL,
    [TranID]      INT           NULL,
    [IssueDate]   DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

