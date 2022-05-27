CREATE TABLE [Report].[IronOfferCycles] (
    [IronOfferCyclesID]         INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]               INT           NOT NULL,
    [OfferCyclesID]             INT           NULL,
    [StartDate]                 DATETIME2 (7) NULL,
    [EndDate]                   DATETIME2 (7) NULL,
    [ControlGroupID]            INT           NULL,
    [OriginalControlGroupID]    INT           NULL,
    [OriginalIronOfferCyclesID] INT           NULL,
    [OriginalTableName]         VARCHAR (100) NULL,
    [CampaignHistoryCopied]     BIT           NULL
);

