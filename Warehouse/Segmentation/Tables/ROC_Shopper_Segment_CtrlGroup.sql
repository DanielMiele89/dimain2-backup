CREATE TABLE [Segmentation].[ROC_Shopper_Segment_CtrlGroup] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NULL,
    [CINID]     INT  NULL,
    [StartDate] DATE NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_Stuff]
    ON [Segmentation].[ROC_Shopper_Segment_CtrlGroup]([StartDate] ASC, [EndDate] ASC)
    INCLUDE([FanID], [CINID]) WITH (FILLFACTOR = 80, DATA_COMPRESSION = PAGE)
    ON [Warehouse_Indexes];

