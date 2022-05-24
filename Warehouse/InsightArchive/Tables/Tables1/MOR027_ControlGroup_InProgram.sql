CREATE TABLE [InsightArchive].[MOR027_ControlGroup_InProgram] (
    [ID]                   INT          IDENTITY (1, 1) NOT NULL,
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (10) NOT NULL,
    [IronOfferID]          INT          NOT NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [ShopperSegment]       VARCHAR (15) NOT NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [FanID]                INT          NOT NULL,
    [PercentageTaken]      INT          NOT NULL,
    [ExcludeFromAnalysis]  BIT          NOT NULL
);

