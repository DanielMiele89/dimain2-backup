CREATE TABLE [InsightArchive].[AviosOffersForUpdate_Old] (
    [CompositeID]   BIGINT       NOT NULL,
    [PartnerID]     INT          NOT NULL,
    [IronOfferID]   INT          NOT NULL,
    [StartDate]     DATETIME     NULL,
    [EndDate]       DATETIME     NULL,
    [StartDate_New] VARCHAR (10) NOT NULL
);

