CREATE TABLE [Derived].[OfferIDs] (
    [IronOfferID]          INT            IDENTITY (-1, -1) NOT NULL,
    [PartnerID]            INT            NOT NULL,
    [PublisherID]          INT            NULL,
    [PublisherID_RewardBI] INT            NOT NULL,
    [OfferCode]            VARCHAR (1000) NOT NULL,
    [OfferIDTypeID]        TINYINT        NULL,
    [ImportDate]           DATETIME2 (7)  NULL,
    CONSTRAINT [PK_Derived_OfferIDs] PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

