CREATE TABLE [Prototype].[BudgetTracker_CampaignFigures] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [InputID]              INT           NOT NULL,
    [BrandID]              SMALLINT      NOT NULL,
    [DayDate]              DATE          NOT NULL,
    [PublisherName]        VARCHAR (30)  NULL,
    [Segment]              VARCHAR (30)  NULL,
    [IronOfferName]        VARCHAR (100) NULL,
    [Investment]           MONEY         NOT NULL,
    [Proportion]           FLOAT (53)    NOT NULL,
    [Budget]               MONEY         NOT NULL,
    [Investment_Forecast]  MONEY         NOT NULL,
    [IronOfferID]          VARCHAR (500) NULL,
    [ForecastedInvestment] DECIMAL (18)  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

