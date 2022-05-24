CREATE TABLE [MI].[OfferReport_Aggregate] (
    [ID]           INT   IDENTITY (1, 1) NOT NULL,
    [OfferID]      INT   NULL,
    [StartDate]    DATE  NULL,
    [EndDate]      DATE  NULL,
    [PartnerID]    INT   NULL,
    [Channel]      BIT   NULL,
    [Sales]        MONEY NULL,
    [IncSales]     REAL  NULL,
    [Transactions] INT   NULL,
    [IncTrans]     REAL  NULL,
    [Spenders]     INT   NULL,
    [IncSpenders]  REAL  NULL,
    [MonthlyDate]  DATE  NULL,
    [isCampaign]   BIT   NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

