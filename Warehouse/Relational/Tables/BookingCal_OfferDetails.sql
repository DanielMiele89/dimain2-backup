CREATE TABLE [Relational].[BookingCal_OfferDetails] (
    [ID]                 INT            IDENTITY (1, 1) NOT NULL,
    [CalendarYear]       INT            NOT NULL,
    [ClientServicesRef]  VARCHAR (40)   NOT NULL,
    [CampaignName]       VARCHAR (200)  NULL,
    [CampaignType]       VARCHAR (100)  NULL,
    [PartnerID]          INT            NULL,
    [BrandID]            INT            NULL,
    [MinOfferRate]       NUMERIC (7, 4) NULL,
    [MaxOfferRate]       NUMERIC (7, 4) NULL,
    [MinSS]              MONEY          NULL,
    [MaxSS]              MONEY          NULL,
    [Campaign_StartDate] DATE           NULL,
    [Campaign_EndDate]   DATE           NULL,
    [Status_StartDate]   DATE           NULL,
    [Status_EndDate]     DATE           NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

