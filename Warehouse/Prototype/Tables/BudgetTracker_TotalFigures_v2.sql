CREATE TABLE [Prototype].[BudgetTracker_TotalFigures_v2] (
    [BrandID]         INT             NULL,
    [DayID]           SMALLINT        NOT NULL,
    [HalfCycleStart]  DATETIME        NULL,
    [StartDay]        SMALLINT        NOT NULL,
    [DayDate]         DATE            NOT NULL,
    [HalfCycleEnd]    DATETIME        NULL,
    [EndDay]          SMALLINT        NOT NULL,
    [Segment]         VARCHAR (500)   NULL,
    [PublisherName]   VARCHAR (500)   NULL,
    [PublisherID]     INT             NULL,
    [CampaignCode]    VARCHAR (50)    NULL,
    [IronOfferID]     VARCHAR (50)    NULL,
    [DailyInvestment] NUMERIC (38, 8) NULL,
    [ForecastID]      VARCHAR (500)   NULL
);

