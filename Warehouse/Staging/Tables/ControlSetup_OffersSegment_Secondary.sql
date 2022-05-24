CREATE TABLE [Staging].[ControlSetup_OffersSegment_Secondary] (
    [IronOfferID]   INT            NOT NULL,
    [IronOfferName] NVARCHAR (200) NULL,
    [StartDate]     DATE           NOT NULL,
    [EndDate]       DATE           NOT NULL,
    [Segment]       VARCHAR (50)   NULL,
    [PartnerID]     INT            NULL,
    [PublisherType] VARCHAR (50)   NULL,
    CONSTRAINT [PK_ControlSetup_OffersSegment_Secondary] PRIMARY KEY CLUSTERED ([IronOfferID] ASC, [StartDate] ASC, [EndDate] ASC)
);

