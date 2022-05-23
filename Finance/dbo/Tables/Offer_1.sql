CREATE TABLE [dbo].[Offer] (
    [OfferID]         INT            IDENTITY (1, 1) NOT NULL,
    [OfferName]       VARCHAR (200)  NULL,
    [StartDate]       DATETIME2 (7)  NULL,
    [EndDate]         DATETIME2 (7)  NULL,
    [PartnerID]       INT            NOT NULL,
    [PublisherID]     SMALLINT       NOT NULL,
    [SourceTypeID]    SMALLINT       NOT NULL,
    [SourceID]        VARCHAR (36)   NOT NULL,
    [CreatedDateTime] DATETIME2 (7)  NOT NULL,
    [UpdatedDateTime] DATETIME2 (7)  NOT NULL,
    [MD5]             VARBINARY (16) NOT NULL,
    CONSTRAINT [PK_Offer] PRIMARY KEY CLUSTERED ([OfferID] ASC) WITH (FILLFACTOR = 90),
    CONSTRAINT [FK_Offer_PartnerID] FOREIGN KEY ([PartnerID]) REFERENCES [dbo].[Partner] ([PartnerID]),
    CONSTRAINT [FK_Offer_PublisherID] FOREIGN KEY ([PublisherID]) REFERENCES [dbo].[Publisher] ([PublisherID]),
    CONSTRAINT [FK_Offer_SourceTypeID] FOREIGN KEY ([SourceTypeID]) REFERENCES [dbo].[SourceType] ([SourceTypeID])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UNIX_Offer_Source]
    ON [dbo].[Offer]([SourceTypeID] ASC, [SourceID] ASC) WITH (FILLFACTOR = 90);

