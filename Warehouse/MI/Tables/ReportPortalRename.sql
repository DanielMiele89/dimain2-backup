CREATE TABLE [MI].[ReportPortalRename] (
    [ID]           TINYINT      IDENTITY (1, 1) NOT NULL,
    [Report]       VARCHAR (50) NOT NULL,
    [ReportRename] VARCHAR (50) NULL,
    CONSTRAINT [PK_MI_ReportPortalRename] PRIMARY KEY CLUSTERED ([ID] ASC)
);

