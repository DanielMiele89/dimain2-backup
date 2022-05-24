CREATE TABLE [MI].[CampaignReport_OfferSplit] (
    [IronOfferID]       INT           NOT NULL,
    [ClientServicesRef] NVARCHAR (30) NOT NULL,
    [SplitName]         NVARCHAR (40) NULL,
    [SSOffer]           BIT           DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([IronOfferID] ASC)
);

