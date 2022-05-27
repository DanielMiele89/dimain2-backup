CREATE TABLE [Relational].[CBP_CampaignNames] (
    [ClientServicesRef] VARCHAR (10)  NOT NULL,
    [CampaignName]      VARCHAR (200) NOT NULL,
    CONSTRAINT [pk_CSREF] PRIMARY KEY CLUSTERED ([ClientServicesRef] ASC, [CampaignName] ASC),
    CONSTRAINT [uc_CBP_CampaignNames_ClientServicesRef] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC) WITH (FILLFACTOR = 80)
);

