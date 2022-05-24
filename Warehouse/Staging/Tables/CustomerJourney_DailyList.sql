CREATE TABLE [Staging].[CustomerJourney_DailyList] (
    [FanID]                 INT          NOT NULL,
    [CustomerJourneyStatus] VARCHAR (24) NULL,
    [LapsFlag]              VARCHAR (11) NOT NULL,
    [Date]                  DATE         NULL,
    [Shortcode]             CHAR (3)     NULL,
    [StartDate]             DATE         NULL,
    [EndDate]               DATE         NULL
);

