CREATE TABLE [MI].[ReportPortalUsage_Raw] (
    [ID]        INT            NOT NULL,
    [Operation] VARCHAR (50)   NULL,
    [UserName]  VARCHAR (50)   NULL,
    [OpDetails] VARCHAR (8000) NULL,
    [UseDate]   DATE           NOT NULL,
    CONSTRAINT [PK_MI_ReportPortalUsage_Raw] PRIMARY KEY CLUSTERED ([ID] ASC)
);

