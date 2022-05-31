CREATE TABLE [Segmentation].[PartnerSettings] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT      NOT NULL,
    [Existing]          SMALLINT NOT NULL,
    [Lapsed]            SMALLINT NOT NULL,
    [RegisteredAtLeast] SMALLINT NOT NULL,
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NULL,
    [CtrlGrp]           TINYINT  NULL,
    [AutomaticRun]      BIT      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings] ([PartnerID]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings] ([Existing]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings] ([Lapsed]) TO [ExcelQuery_DataOps]
    AS [dbo];


GO
GRANT SELECT
    ON [Segmentation].[PartnerSettings] ([EndDate]) TO [ExcelQuery_DataOps]
    AS [dbo];

