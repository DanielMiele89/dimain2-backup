CREATE TABLE [Email].[LionSendDetails] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [LionSendID]   INT           NULL,
    [LionSendName] VARCHAR (100) NULL,
    [CampaignKey]  VARCHAR (100) NULL,
    [SendDate]     DATE          NULL
);

