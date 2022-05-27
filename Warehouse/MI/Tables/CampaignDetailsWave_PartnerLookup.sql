CREATE TABLE [MI].[CampaignDetailsWave_PartnerLookup] (
    [ID]                INT          IDENTITY (1, 1) NOT NULL,
    [ClientServicesRef] VARCHAR (40) NOT NULL,
    [StartDate]         DATE         NOT NULL,
    [PartnerID]         INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UN_CampaignDetailsWave_PartnerLookup] UNIQUE NONCLUSTERED ([ClientServicesRef] ASC, [StartDate] ASC, [PartnerID] ASC)
);

