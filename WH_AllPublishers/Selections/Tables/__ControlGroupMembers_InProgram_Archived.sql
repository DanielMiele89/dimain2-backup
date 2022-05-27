CREATE TABLE [Selections].[__ControlGroupMembers_InProgram_Archived] (
    [PublisherID]          INT          NOT NULL,
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (10) NOT NULL,
    [IronOfferID]          INT          NOT NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [FanID]                INT          NOT NULL,
    [PercentageTaken]      INT          NOT NULL,
    [ExcludeFromAnalysis]  BIT          NOT NULL
);

