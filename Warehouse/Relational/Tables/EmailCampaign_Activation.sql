CREATE TABLE [Relational].[EmailCampaign_Activation] (
    [ID]                  INT           IDENTITY (1, 1) NOT NULL,
    [SendDate]            DATETIME      NULL,
    [CampaignDescription] VARCHAR (100) NULL,
    [EmailStatus]         VARCHAR (10)  NULL,
    [EndDate]             DATETIME      NULL
);

