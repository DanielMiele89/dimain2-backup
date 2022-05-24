CREATE TABLE [Relational].[BookingCal_OfferMarketingSettings] (
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [CalendarYear]      INT           NOT NULL,
    [ClientServicesRef] VARCHAR (40)  NOT NULL,
    [MarketingSupport]  VARCHAR (100) NULL,
    [EmailTesting]      VARCHAR (100) NULL,
    [ATL]               BIT           NULL,
    [Status_StartDate]  DATE          NULL,
    [Status_EndDate]    DATE          NULL
);

