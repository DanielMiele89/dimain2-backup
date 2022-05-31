CREATE TABLE [Ewan].[Incrementality_Proposal3_design1_sanity] (
    [CycleID]        INT          NULL,
    [CycleStartDate] DATE         NULL,
    [CycleEndDate]   DATE         NULL,
    [BrandID]        INT          NULL,
    [BrandName]      VARCHAR (30) NULL,
    [GSBBRating]     VARCHAR (12) NULL,
    [IsTest]         INT          NULL,
    [Spenders]       INT          NULL,
    [Transactions]   INT          NULL,
    [Spend]          MONEY        NULL
);

