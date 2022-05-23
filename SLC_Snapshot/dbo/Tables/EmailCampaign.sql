CREATE TABLE [dbo].[EmailCampaign] (
    [ID]                 INT            IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [CampaignKey]        NVARCHAR (8)   NOT NULL,
    [EmailKey]           NVARCHAR (16)  NULL,
    [Folder]             NVARCHAR (510) NULL,
    [ListKey]            NVARCHAR (16)  NULL,
    [ListName]           NVARCHAR (510) NULL,
    [QueryKey]           NVARCHAR (16)  NULL,
    [QueryName]          NVARCHAR (510) NULL,
    [CampaignName]       NVARCHAR (255) NOT NULL,
    [Subject]            NVARCHAR (510) NULL,
    [SendDate]           DATETIME       NOT NULL,
    [EmailsSent]         INT            NOT NULL,
    [EmailsDelivered]    INT            NOT NULL,
    [UniqueOpens]        INT            NULL,
    [UniqueClicks]       INT            NULL,
    [UniqueUnsubscribes] INT            NULL,
    [UniqueHardBounces]  INT            NULL,
    [ImportDate]         DATETIME       NOT NULL,
    CONSTRAINT [PK_EmailCampaign] PRIMARY KEY CLUSTERED ([ID] ASC)
);

