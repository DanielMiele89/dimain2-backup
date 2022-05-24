CREATE TABLE [InsightArchive].[SegmentPOC_SSCampaigns] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [Retailer]         VARCHAR (20) NULL,
    [StartDate]        DATE         NULL,
    [EndDate]          DATE         NULL,
    [Cycles]           REAL         NULL,
    [Segment]          VARCHAR (20) NULL,
    [IronOfferID]      INT          NULL,
    [SpendStretchFlag] BIT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

