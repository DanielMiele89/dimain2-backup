CREATE TABLE [InsightArchive].[WA215_ControlGroup_InProgram] (
    [PartnerID]            INT          NOT NULL,
    [ClientServicesRef]    VARCHAR (10) NOT NULL,
    [IronOfferID]          INT          NULL,
    [ShopperSegmentTypeID] INT          NOT NULL,
    [StartDate]            DATETIME     NULL,
    [EndDate]              DATETIME     NULL,
    [FanID]                INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

