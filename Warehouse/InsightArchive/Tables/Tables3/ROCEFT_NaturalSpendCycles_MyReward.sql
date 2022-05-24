CREATE TABLE [InsightArchive].[ROCEFT_NaturalSpendCycles_MyReward] (
    [BrandID]             INT        NOT NULL,
    [CycleID]             INT        NOT NULL,
    [Seasonality_CycleID] INT        NOT NULL,
    [Segment]             INT        NOT NULL,
    [SegmentSize]         INT        NULL,
    [Promoted]            INT        NULL,
    [Demoted]             INT        NULL,
    [OnOffer]             INT        NULL,
    [Sales]               MONEY      NULL,
    [OnlineSales]         MONEY      NULL,
    [Transactions]        INT        NULL,
    [OnlineTransactions]  INT        NULL,
    [Spenders]            INT        NULL,
    [OnlineSpenders]      INT        NULL,
    [DecayRate]           FLOAT (53) NULL,
    [PromotionRate]       FLOAT (53) NULL,
    [OnOfferRate]         FLOAT (53) NULL,
    PRIMARY KEY CLUSTERED ([BrandID] ASC, [CycleID] ASC, [Seasonality_CycleID] ASC, [Segment] ASC)
);

