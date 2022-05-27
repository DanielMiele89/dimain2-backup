CREATE TABLE [InsightArchive].[CustomerEngagementScoring_Campaigns] (
    [IronOfferID]       INT           NULL,
    [IronOfferName]     VARCHAR (200) NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    [PartnerID]         INT           NULL,
    [ClientServicesRef] VARCHAR (50)  NULL,
    [BrandID]           INT           NULL,
    [BrandName]         VARCHAR (100) NULL,
    [SuperSegment]      VARCHAR (50)  NULL,
    [Segment]           VARCHAR (50)  NULL
);


GO
CREATE CLUSTERED INDEX [cix_IronOfferID]
    ON [InsightArchive].[CustomerEngagementScoring_Campaigns]([IronOfferID] ASC);

