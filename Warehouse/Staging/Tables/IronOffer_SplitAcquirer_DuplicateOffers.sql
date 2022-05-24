CREATE TABLE [Staging].[IronOffer_SplitAcquirer_DuplicateOffers] (
    [ID]                    INT IDENTITY (1, 1) NOT NULL,
    [IronOfferID_Original]  INT NOT NULL,
    [IronOfferID_Duplicate] INT NOT NULL,
    [Active]                BIT NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_IronOffer_SplitAcquirer_DuplicateOffers_ID]
    ON [Staging].[IronOffer_SplitAcquirer_DuplicateOffers]([ID] ASC);

