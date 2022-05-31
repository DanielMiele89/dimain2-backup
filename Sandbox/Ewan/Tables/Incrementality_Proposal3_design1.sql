CREATE TABLE [Ewan].[Incrementality_Proposal3_design1] (
    [CycleID]        INT          NULL,
    [CycleStartDate] DATE         NULL,
    [CycleEndDate]   DATE         NULL,
    [PartnerID]      INT          NULL,
    [PartnerName]    VARCHAR (30) NULL,
    [SectorName]     VARCHAR (30) NULL,
    [IronOfferID]    INT          NULL,
    [IronOfferName]  VARCHAR (37) NULL,
    [SegmentName]    VARCHAR (12) NULL,
    [CashbackRate]   FLOAT (53)   NULL,
    [EarningCount]   VARCHAR (10) NULL,
    [EarningLimit]   INT          NULL,
    [GSBBRating]     VARCHAR (12) NULL,
    [IsTest]         INT          NULL,
    [Cardholders]    INT          NULL,
    [Spenders]       INT          NULL,
    [Transactions]   INT          NULL,
    [Spend]          MONEY        NULL,
    [Cashback]       MONEY        NULL
);

