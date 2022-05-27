CREATE TABLE [Staging].[ROC_Segmentation_Descriptions] (
    [SegmentID]          INT          IDENTITY (1, 1) NOT NULL,
    [SegmentDescription] VARCHAR (35) NOT NULL,
    PRIMARY KEY CLUSTERED ([SegmentID] ASC)
);

