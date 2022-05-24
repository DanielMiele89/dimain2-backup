CREATE TABLE [Staging].[CampaignPlanning_Segments] (
    [HTMID]                   TINYINT       NOT NULL,
    [HTM_Description]         NVARCHAR (50) NULL,
    [SuperSegmentID]          TINYINT       NULL,
    [SuperSegmentDescription] VARCHAR (50)  NULL,
    CONSTRAINT [pk_HTMID] PRIMARY KEY CLUSTERED ([HTMID] ASC)
);

