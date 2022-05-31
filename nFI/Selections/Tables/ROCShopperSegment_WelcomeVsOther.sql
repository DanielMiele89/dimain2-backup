CREATE TABLE [Selections].[ROCShopperSegment_WelcomeVsOther] (
    [OfferCombinationID]    INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID_Welcome]   INT NOT NULL,
    [IronOfferID_Launch]    INT NULL,
    [IronOfferID_Universal] INT NULL,
    CONSTRAINT [OFFERCOMBINATIONID] PRIMARY KEY CLUSTERED ([OfferCombinationID] ASC)
);

