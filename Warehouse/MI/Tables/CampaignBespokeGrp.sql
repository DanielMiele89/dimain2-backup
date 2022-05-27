CREATE TABLE [MI].[CampaignBespokeGrp] (
    [FanID]       INT           NOT NULL,
    [IronOfferID] INT           NOT NULL,
    [SDate]       DATE          NULL,
    [EDate]       DATE          NULL,
    [BespokeGrp]  VARCHAR (400) NOT NULL,
    CONSTRAINT [pk_FanOfferID] PRIMARY KEY CLUSTERED ([FanID] ASC, [IronOfferID] ASC)
);

