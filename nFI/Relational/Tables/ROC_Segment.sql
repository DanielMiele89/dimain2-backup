CREATE TABLE [Relational].[ROC_Segment] (
    [ID]                 TINYINT      NOT NULL,
    [SegmentDescription] VARCHAR (25) NULL,
    [SegmentType]        VARCHAR (10) NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IDX_RS]
    ON [Relational].[ROC_Segment]([SegmentDescription] ASC);


GO
CREATE NONCLUSTERED INDEX [IDX_RST]
    ON [Relational].[ROC_Segment]([SegmentType] ASC);

