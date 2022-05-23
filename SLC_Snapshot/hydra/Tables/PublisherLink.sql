CREATE TABLE [hydra].[PublisherLink] (
    [PublisherLinkID]  UNIQUEIDENTIFIER NOT NULL,
    [HydraPublisherID] UNIQUEIDENTIFIER NOT NULL,
    [ClubID]           INT              NOT NULL,
    CONSTRAINT [PK_PublisherLink] PRIMARY KEY CLUSTERED ([PublisherLinkID] ASC)
);

