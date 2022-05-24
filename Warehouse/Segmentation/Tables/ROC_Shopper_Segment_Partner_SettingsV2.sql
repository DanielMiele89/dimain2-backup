CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] (
    [ID]          INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]   INT      NOT NULL,
    [Acquire]     SMALLINT NOT NULL,
    [Acquire_Pct] INT      NOT NULL,
    [Lapsed]      SMALLINT NOT NULL,
    [StartDate]   DATE     NOT NULL,
    [EndDate]     DATE     NULL,
    [AutoRun]     BIT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] ([EndDate]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] ([Lapsed]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] ([Acquire]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_SettingsV2] ([PartnerID]) TO [ExcelQuery_DataOps]
    AS [dbo];

