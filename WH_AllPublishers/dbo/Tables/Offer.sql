CREATE TABLE [dbo].[Offer] (
    [OfferID]         INT           IDENTITY (1, 1) NOT NULL,
    [OfferName]       VARCHAR (200) NULL,
    [ClubID]          INT           NOT NULL,
    [PublisherID]     INT           NOT NULL,
    [StartDateTime]   DATETIME2 (7) NULL,
    [EndDateTime]     DATETIME2 (7) NULL,
    [PartnerID]       INT           NOT NULL,
    [RetailerID]      INT           NOT NULL,
    [CampaignType]    VARCHAR (50)  NULL,
    [SegmentName]     VARCHAR (50)  NULL,
    [SourceID]        VARCHAR (36)  NOT NULL,
    [SourceTypeID]    INT           NOT NULL,
    [SourceAddedDate] DATE          NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [UpdatedDateTime] DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_Offer] PRIMARY KEY CLUSTERED ([OfferID] ASC),
    CONSTRAINT [FK_Offer_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);

