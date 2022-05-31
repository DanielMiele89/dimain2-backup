CREATE TABLE [Selections].[ROC_Segmentation_vs_OfferType] (
    [ID]           SMALLINT IDENTITY (1, 1) NOT NULL,
    [OfferTypeID]  TINYINT  NOT NULL,
    [ROCSegmentID] SMALLINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [i_ROC_Segmentation_vs_OfferType_OfferTypeID_RocSegmentID]
    ON [Selections].[ROC_Segmentation_vs_OfferType]([OfferTypeID] ASC, [ROCSegmentID] ASC);

