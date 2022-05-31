CREATE TABLE [Ewan].[Incrementality_Proposal3_design2_aggregated_formatted] (
    [IsSanityBrand]       INT           NULL,
    [CycleID]             INT           NULL,
    [CycleStartDate]      DATE          NULL,
    [CalDay]              INT           NULL,
    [GSBBRating]          VARCHAR (12)  NULL,
    [SectorName]          VARCHAR (50)  NULL,
    [PartnerName]         VARCHAR (100) NULL,
    [Test_Spend]          MONEY         NULL,
    [Test_Cardholders]    INT           NULL,
    [Control_Spend]       MONEY         NULL,
    [Control_Cardholders] INT           NULL
);

