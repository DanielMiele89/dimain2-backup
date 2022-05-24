CREATE TABLE [Staging].[ROC_Segmentation_Offers] (
    [ID]           INT     IDENTITY (1, 1) NOT NULL,
    [IronOfferID]  INT     NOT NULL,
    [PartnerID]    INT     NOT NULL,
    [SegmentID]    TINYINT NULL,
    [CurrentOffer] BIT     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

