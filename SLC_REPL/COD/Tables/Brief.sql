CREATE TABLE [COD].[Brief] (
    [ID]            INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CampaignID]    INT            NOT NULL,
    [BriefName]     NVARCHAR (128) NOT NULL,
    [BriefStatus]   INT            NOT NULL,
    [BriefBudget]   BIGINT         NOT NULL,
    [BriefOverride] FLOAT (53)     NOT NULL,
    [StartDate]     DATETIME       NOT NULL,
    [EndDate]       DATETIME       NOT NULL,
    [CreatedDate]   DATETIME       NOT NULL,
    CONSTRAINT [PK__Brief__3214EC272707BA1D] PRIMARY KEY CLUSTERED ([ID] ASC)
);

