CREATE TABLE [Staging].[AmexOfferStage_OfferNameToPublisher] (
    [PublisherID]           INT          NOT NULL,
    [OfferIDPrefix3]        VARCHAR (3)  NOT NULL,
    [PublisherCodeRawFiles] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AmexOfferStage_OfferNameToPublisher] PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

