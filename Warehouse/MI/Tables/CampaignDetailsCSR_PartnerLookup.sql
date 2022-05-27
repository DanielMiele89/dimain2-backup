CREATE TABLE [MI].[CampaignDetailsCSR_PartnerLookup] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (40) NOT NULL,
    [PartnerID]         INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UN_CampaignDetailsCSR_PartnerLookup] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [PartnerID] ASC)
);

