CREATE TABLE [dbo].[CustomerJourney] (
    [FanID]                 INT          NOT NULL,
    [CustomerJourneyStatus] VARCHAR (24) NOT NULL,
    [LapsFlag]              VARCHAR (11) NOT NULL,
    [Date]                  DATE         NULL,
    [Shortcode]             CHAR (3)     NULL,
    [StartDate]             DATE         NOT NULL,
    [EndDate]               DATE         NULL,
    CONSTRAINT [PK_CustomerJourney] PRIMARY KEY CLUSTERED ([FanID] ASC, [CustomerJourneyStatus] ASC, [StartDate] ASC)
);

