CREATE TABLE [Selections].[CampaignSetup_PartnerDataDedupe] (
    [ID]        INT            IDENTITY (1, 1) NOT NULL,
    [PartnerID] INT            NULL,
    [TableName] VARCHAR (8000) NULL,
    [Action]    VARCHAR (20)   NULL,
    [StartDate] DATE           NULL,
    [EndDate]   DATE           NULL
);

