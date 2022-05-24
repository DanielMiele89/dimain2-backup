CREATE TABLE [MI].[CampaignPlanning_BaseOffer] (
    [PartnerName] VARCHAR (100) NOT NULL,
    [StartDate]   DATE          NOT NULL,
    [EndDate]     DATE          NOT NULL,
    [WeekNumb]    INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([WeekNumb] ASC, [PartnerName] ASC)
);

