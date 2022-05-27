CREATE TABLE [InsightArchive].[SKY002_ControlGroup_InProgram] (
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (6)  NOT NULL,
    [IronOfferID]          INT          NOT NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [ShopperSegment]       VARCHAR (15) NOT NULL,
    [StartDate]            VARCHAR (10) NOT NULL,
    [EndDate]              VARCHAR (10) NOT NULL,
    [FanID]                INT          NOT NULL,
    [PercentageTaken]      INT          NOT NULL,
    [ExcludeFromAnalysis]  INT          NOT NULL
);

