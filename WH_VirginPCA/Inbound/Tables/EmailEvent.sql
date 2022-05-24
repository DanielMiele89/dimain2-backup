﻿CREATE TABLE [Inbound].[EmailEvent] (
    [ID]               INT            IDENTITY (1, 1) NOT NULL,
    [EventDate]        DATETIME       NULL,
    [FanID]            INT            NOT NULL,
    [CampaignKey]      VARCHAR (8)    NOT NULL,
    [EmailEventCodeID] INT            NOT NULL,
    [ClickURL]         VARCHAR (2000) NULL,
    [ImportedDate]     DATETIME       NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

