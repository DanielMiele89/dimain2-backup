CREATE TABLE [Staging].[IronOffer_Campaign_Type] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (40) NULL,
    [CampaignTypeID]    INT          NULL,
    [IsTrigger]         BIT          NULL,
    [ControlPercentage] TINYINT      NULL
);

