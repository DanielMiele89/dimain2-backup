CREATE TABLE [SmartEmail].[RakutenCampaign_March2021] (
    [ID]             INT          IDENTITY (1, 1) NOT NULL,
    [FanID]          INT          NOT NULL,
    [CampaignStatus] VARCHAR (7)  NOT NULL,
    [ControlFlag]    INT          NOT NULL,
    [RakutenCode]    VARCHAR (25) NULL,
    [SentReminder]   BIT          NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

