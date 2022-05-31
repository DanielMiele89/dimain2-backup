CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Types] (
    [ID]                 SMALLINT     IDENTITY (1, 1) NOT NULL,
    [SegmentName]        VARCHAR (50) NOT NULL,
    [SuperSegmentTypeID] INT          NOT NULL,
    [SegmentCode]        VARCHAR (10) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

