CREATE TABLE [dbo].[RedeemAction] (
    [ID]      INT      IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [TransID] INT      NOT NULL,
    [Status]  INT      NOT NULL,
    [Date]    DATETIME NOT NULL,
    CONSTRAINT [PK_RedeemAction] PRIMARY KEY CLUSTERED ([ID] ASC)
);

