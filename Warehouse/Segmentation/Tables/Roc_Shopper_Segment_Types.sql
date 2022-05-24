CREATE TABLE [Segmentation].[Roc_Shopper_Segment_Types] (
    [ID]          SMALLINT     IDENTITY (1, 1) NOT NULL,
    [SegmentName] VARCHAR (50) NOT NULL,
    [SegmentCode] VARCHAR (10) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

