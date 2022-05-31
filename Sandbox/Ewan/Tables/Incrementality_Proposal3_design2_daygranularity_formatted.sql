CREATE TABLE [Ewan].[Incrementality_Proposal3_design2_daygranularity_formatted] (
    [IsSanityBrand]  INT           NULL,
    [IsTest]         INT           NULL,
    [CycleID]        INT           NULL,
    [CycleStartDate] DATE          NULL,
    [CalDate]        DATE          NULL,
    [CalDay]         INT           NULL,
    [GSBBRating]     VARCHAR (12)  NULL,
    [SectorName]     VARCHAR (50)  NULL,
    [PartnerName]    VARCHAR (100) NULL,
    [IronOfferID]    INT           NULL,
    [Spend]          MONEY         NULL,
    [Cardholders]    INT           NULL
);

