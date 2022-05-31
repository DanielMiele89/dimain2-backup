CREATE TABLE [Segmentation].[ROC_Shopper_Segment_To_Offers] (
    [ID]                   INT      IDENTITY (1, 1) NOT NULL,
    [IronOfferID]          INT      NOT NULL,
    [ShopperSegmentTypeID] SMALLINT NULL,
    [LiveOffer]            BIT      DEFAULT ((0)) NULL,
    [WelcomeOffer]         BIT      DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_ROC_Shopper_Segment_To_Offers_IronOfferID]
    ON [Segmentation].[ROC_Shopper_Segment_To_Offers]([IronOfferID] ASC);

