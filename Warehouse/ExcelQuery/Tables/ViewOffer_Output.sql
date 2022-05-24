CREATE TABLE [ExcelQuery].[ViewOffer_Output] (
    [ID]                     INT IDENTITY (1, 1) NOT NULL,
    [FanID]                  INT NULL,
    [MarketableByEmail]      INT NULL,
    [Pre_EventCount]         INT NULL,
    [Pre_CampaignCount]      INT NULL,
    [Pre_WebLoginDays]       INT NULL,
    [Pre_WebLogin]           INT NULL,
    [Campaign_EventCount]    INT NULL,
    [Campaign_CampaignCount] INT NULL,
    [Campaign_WebLoginDays]  INT NULL,
    [Campaign_WebLogin]      INT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

