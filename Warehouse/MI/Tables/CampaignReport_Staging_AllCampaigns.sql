CREATE TABLE [MI].[CampaignReport_Staging_AllCampaigns] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] NVARCHAR (30) NULL,
    [StartDate]         DATE          NULL,
    [EndDate]           DATE          NULL,
    [isCalculated]      BIT           NULL,
    [isIncomplete]      BIT           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

