CREATE TABLE [Relational].[CampaignLionSendIDs] (
    [CampaignKey]         NVARCHAR (8)  NOT NULL,
    [LionSendID]          INT           NULL,
    [EmailType]           VARCHAR (1)   NULL,
    [Reference]           VARCHAR (10)  NULL,
    [HardCoded_OfferFrom] INT           NULL,
    [HardCoded_OfferTo]   INT           NULL,
    [EmailName]           VARCHAR (100) NULL,
    [ClubID]              INT           NULL,
    [TrueSolus]           BIT           NULL,
    PRIMARY KEY CLUSTERED ([CampaignKey] ASC)
);

