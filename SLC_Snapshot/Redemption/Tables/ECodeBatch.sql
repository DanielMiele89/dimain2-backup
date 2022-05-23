CREATE TABLE [Redemption].[ECodeBatch] (
    [ID]         INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [LoadDate]   DATETIME NOT NULL,
    [LoadedBy]   INT      NOT NULL,
    [ExpiryDate] DATE     NOT NULL,
    [RedeemID]   INT      NOT NULL,
    CONSTRAINT [PK_ECodeBatch_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);

