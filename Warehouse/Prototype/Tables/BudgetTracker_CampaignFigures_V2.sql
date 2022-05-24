CREATE TABLE [Prototype].[BudgetTracker_CampaignFigures_V2] (
    [InputID]              INT             NULL,
    [BrandID]              INT             NULL,
    [DayDate]              DATE            NULL,
    [PublisherName]        VARCHAR (500)   NULL,
    [Segment]              VARCHAR (500)   NULL,
    [IronOfferName]        VARCHAR (500)   NULL,
    [Investment]           DECIMAL (10, 2) NULL,
    [Proportion]           DECIMAL (18)    NULL,
    [Budget]               DECIMAL (10, 2) NULL,
    [Investment_Forecast]  DECIMAL (10, 2) NULL,
    [IronOfferID]          VARCHAR (500)   NULL,
    [ForecastedInvestment] DECIMAL (10, 2) NULL
);

