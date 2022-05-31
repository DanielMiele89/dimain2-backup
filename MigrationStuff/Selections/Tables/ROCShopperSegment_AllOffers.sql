CREATE TABLE [Selections].[ROCShopperSegment_AllOffers] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]          INT      NOT NULL,
    [LiveOffer]            BIT      NOT NULL,
    [ShopperSegmentTypeID] INT      NULL,
    [OfferType]            INT      NOT NULL,
    [SecondaryOffer]       BIT      NULL,
    [DateAdded]            DATETIME NOT NULL,
    CONSTRAINT [ID_ALLOFFERS_PRIMARYKEY] PRIMARY KEY CLUSTERED ([ID] ASC)
);

