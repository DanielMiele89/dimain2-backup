CREATE TABLE [Staging].[R_0057_DataTableV2] (
    [StartOfWeek]           DATE           NULL,
    [SendDate]              DATE           NULL,
    [ClubID]                INT            NOT NULL,
    [CampaignName]          NVARCHAR (255) NOT NULL,
    [CustomerJourneyStatus] VARCHAR (8)    NOT NULL,
    [WeekNumber]            TINYINT        NOT NULL,
    [Delivered]             INT            NULL,
    [Opened]                INT            NULL,
    [Clicked]               INT            NULL,
    [Unsubscribed]          INT            NULL
);

