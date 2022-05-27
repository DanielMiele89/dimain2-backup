CREATE TABLE [Report].[IronOfferCycles_Temp] (
    [IronOfferID]               INT           NOT NULL,
    [OfferCyclesID]             INT           NULL,
    [ControlGroupID]            INT           NULL,
    [OriginalOfferCyclesID]     INT           NOT NULL,
    [OriginalControlGroupID]    INT           NULL,
    [OriginalIronOfferCyclesID] INT           NOT NULL,
    [OriginalTableName]         VARCHAR (42)  NOT NULL,
    [StartDate]                 DATETIME2 (7) NULL,
    [EndDate]                   DATETIME2 (7) NULL
);

