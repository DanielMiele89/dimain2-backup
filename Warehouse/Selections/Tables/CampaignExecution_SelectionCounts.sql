CREATE TABLE [Selections].[CampaignExecution_SelectionCounts] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [EmailDate]         DATE          NULL,
    [OutputTableName]   VARCHAR (100) NULL,
    [IronOfferID]       INT           NULL,
    [CountSelected]     INT           NULL,
    [RunDateTime]       DATETIME      NULL,
    [NewCampaign]       BIT           NULL,
    [ClientServicesRef] VARCHAR (10)  NULL
);

