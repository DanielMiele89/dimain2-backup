CREATE TABLE [MI].[CampaignReportLog_Extended] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] NVARCHAR (30) NULL,
    [StartDate]         DATE          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

