CREATE TABLE [dbo].[IronOffer_OLD] (
    [IronOfferID]     INT           NOT NULL,
    [IronOfferName]   VARCHAR (200) NULL,
    [StartDate]       DATETIME      NULL,
    [EndDate]         DATETIME      NULL,
    [PartnerID]       INT           NOT NULL,
    [PublisherID]     SMALLINT      NOT NULL,
    [CreatedDateTime] DATETIME2 (7) NOT NULL,
    [UpdatedDateTime] DATETIME2 (7) NULL,
    CONSTRAINT [PK_IronOffer_OLD] PRIMARY KEY CLUSTERED ([IronOfferID] ASC),
    CONSTRAINT [FK_IronOffer_PartnerID_OLD] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner_OLD] ([PartnerID]),
    CONSTRAINT [FK_IronOffer_PublisherID_OLD] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher_OLD] ([PublisherID])
);

