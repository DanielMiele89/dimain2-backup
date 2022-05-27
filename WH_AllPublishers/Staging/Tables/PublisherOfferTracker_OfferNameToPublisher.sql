CREATE TABLE [Staging].[PublisherOfferTracker_OfferNameToPublisher] (
    [PublisherID]           INT          NOT NULL,
    [PublisherID_RewardBI]  INT          NOT NULL,
    [OfferCodePrefix3]      VARCHAR (3)  NOT NULL,
    [PublisherCodeRawFiles] VARCHAR (50) NOT NULL,
    CONSTRAINT [PK_AmexOfferStage_OfferNameToPublisher] PRIMARY KEY CLUSTERED ([PublisherID] ASC)
);

