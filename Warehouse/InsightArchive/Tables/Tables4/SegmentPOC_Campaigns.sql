CREATE TABLE [InsightArchive].[SegmentPOC_Campaigns] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [PartnerID]          INT           NULL,
    [StartDate]          DATE          NULL,
    [ClientServicesRef]  VARCHAR (20)  NULL,
    [CampaignName]       VARCHAR (200) NULL,
    [SuperSegment]       VARCHAR (20)  NULL,
    [Segment]            VARCHAR (20)  NULL,
    [IronOfferID]        INT           NULL,
    [ModernALS]          BIT           NULL,
    [InProgrammeControl] BIT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

