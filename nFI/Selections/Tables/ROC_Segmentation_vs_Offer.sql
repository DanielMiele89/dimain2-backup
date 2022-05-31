CREATE TABLE [Selections].[ROC_Segmentation_vs_Offer] (
    [ID]          INT     IDENTITY (1, 1) NOT NULL,
    [OfferTypeID] TINYINT NOT NULL,
    [IronOfferID] INT     NOT NULL,
    [DoNotUse]    BIT     DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_ROC_Segmentation_vs_Offer_IronOfferID]
    ON [Selections].[ROC_Segmentation_vs_Offer]([IronOfferID] ASC);


GO
CREATE NONCLUSTERED INDEX [i_ROC_Segmentation_vs_Offer_OfferTypeID]
    ON [Selections].[ROC_Segmentation_vs_Offer]([OfferTypeID] ASC);

