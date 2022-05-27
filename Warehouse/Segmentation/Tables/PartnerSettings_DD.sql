CREATE TABLE [Segmentation].[PartnerSettings_DD] (
    [ID]        INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT      NOT NULL,
    [Acquire]   SMALLINT NOT NULL,
    [Lapsed]    SMALLINT NOT NULL,
    [Shopper]   SMALLINT DEFAULT ((0)) NOT NULL,
    [AutoRun]   BIT      DEFAULT ((0)) NOT NULL,
    [StartDate] DATE     NOT NULL,
    [EndDate]   DATE     NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);




GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings_DD] ([Shopper]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings_DD] ([PartnerID]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings_DD] ([Lapsed]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings_DD] ([EndDate]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings_DD] ([Acquire]) TO [ExcelQuery_DataOps]
    AS [dbo];

