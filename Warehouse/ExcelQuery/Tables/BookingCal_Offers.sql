CREATE TABLE [ExcelQuery].[BookingCal_Offers] (
    [CalendarYear]         INT            NOT NULL,
    [ClientServicesRef]    VARCHAR (40)   NOT NULL,
    [CampaignName]         VARCHAR (100)  NULL,
    [CampaignType]         VARCHAR (100)  NULL,
    [PartnerID]            INT            NULL,
    [BrandID]              INT            NULL,
    [MinOfferRate]         NUMERIC (7, 4) NULL,
    [MaxOfferRate]         NUMERIC (7, 4) NULL,
    [MinSS]                MONEY          NULL,
    [MaxSS]                MONEY          NULL,
    [StartDate]            DATE           NULL,
    [Enddate]              DATE           NULL,
    [DateForecastExpected] DATE           NULL,
    [DateBriefSubmitted]   DATE           NULL,
    [ApprovedByRetailer]   INT            NULL,
    [ApprovedByRBSG]       INT            NULL,
    [MarketingSupport]     VARCHAR (100)  NULL,
    [EmailTesting]         VARCHAR (100)  NULL,
    [ATL]                  INT            NULL,
    [Inserted]             DATETIME       NULL
);

