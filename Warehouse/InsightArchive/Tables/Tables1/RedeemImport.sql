CREATE TABLE [InsightArchive].[RedeemImport] (
    [Date]        DATE  NOT NULL,
    [FanID]       INT   NOT NULL,
    [TransID]     INT   NOT NULL,
    [RedeemValue] MONEY NOT NULL,
    [ID]          INT   IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

