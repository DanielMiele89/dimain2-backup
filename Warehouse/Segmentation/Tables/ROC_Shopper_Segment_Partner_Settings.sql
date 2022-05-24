CREATE TABLE [Segmentation].[ROC_Shopper_Segment_Partner_Settings] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT      NOT NULL,
    [Acquire]           SMALLINT NOT NULL,
    [Lapsed]            SMALLINT NOT NULL,
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NULL,
    [AutoRun]           BIT      DEFAULT ((0)) NOT NULL,
    [Shopper]           SMALLINT CONSTRAINT [Shopper_default_value] DEFAULT ((0)) NOT NULL,
    [RegisteredAtLeast] SMALLINT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ([Shopper]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ([EndDate]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ([Lapsed]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ([Acquire]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[ROC_Shopper_Segment_Partner_Settings] ([PartnerID]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT UPDATE
    ON OBJECT::[Segmentation].[ROC_Shopper_Segment_Partner_Settings] TO [Zoe]
    AS [dbo];


GO
GRANT SELECT
    ON OBJECT::[Segmentation].[ROC_Shopper_Segment_Partner_Settings] TO [Zoe]
    AS [dbo];


GO
GRANT INSERT
    ON OBJECT::[Segmentation].[ROC_Shopper_Segment_Partner_Settings] TO [Zoe]
    AS [dbo];

