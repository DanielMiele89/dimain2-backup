CREATE TABLE [Ewan].[Incrementality_Proposal3_design2_daygranularity] (
    [CycleID]        INT          NULL,
    [CycleStartDate] DATE         NULL,
    [CycleEndDate]   DATE         NULL,
    [CalDate]        DATE         NULL,
    [CalDay]         INT          NULL,
    [IronOfferID]    INT          NULL,
    [IsTest]         INT          NULL,
    [GSBBRating]     VARCHAR (12) NULL,
    [Cardholders]    INT          NULL,
    [Spenders]       INT          NULL,
    [Transactions]   INT          NULL,
    [Spend]          MONEY        NULL,
    [Cashback]       MONEY        NULL,
    [IsSanityBrand]  INT          NULL
);

