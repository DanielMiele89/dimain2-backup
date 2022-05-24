CREATE TABLE [Derived].[AccountAmendments] (
    [ID]                     INT           IDENTITY (1, 1) NOT NULL,
    [FanID]                  INT           NOT NULL,
    [Amount]                 MONEY         NULL,
    [AmendmentDate]          DATETIME2 (7) NULL,
    [AccountAmendmentTypeID] INT           NULL,
    [AddedDate]              DATETIME2 (7) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

