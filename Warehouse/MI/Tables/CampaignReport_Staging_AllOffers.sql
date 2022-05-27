CREATE TABLE [MI].[CampaignReport_Staging_AllOffers] (
    [ID]           INT           IDENTITY (1, 1) NOT NULL,
    [IronOfferID]  INT           NOT NULL,
    [StartDate]    DATE          NOT NULL,
    [EndDate]      DATE          NOT NULL,
    [PartnerID]    INT           NOT NULL,
    [CashbackRate] INT           NOT NULL,
    [SpendStretch] INT           NOT NULL,
    [isCalculated] BIT           NOT NULL,
    [isIncomplete] BIT           NOT NULL,
    [OfferName]    NVARCHAR (50) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

