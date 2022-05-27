CREATE TABLE [Report].[ControlSetup_OffersSegment] (
    [PublisherID]   INT            NULL,
    [PublisherName] VARCHAR (100)  NULL,
    [RetailerID]    INT            NULL,
    [PartnerID]     INT            NULL,
    [RetailerName]  VARCHAR (100)  NULL,
    [OfferID]       INT            NOT NULL,
    [IronOfferID]   INT            NOT NULL,
    [OfferName]     NVARCHAR (200) NULL,
    [StartDate]     DATETIME2 (7)  NOT NULL,
    [EndDate]       DATETIME2 (7)  NOT NULL,
    [SegmentID]     TINYINT        NULL,
    [SegmentName]   VARCHAR (50)   NULL,
    CONSTRAINT [PK_ControlSetup_OffersSegment_Warehouse] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

