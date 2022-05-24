CREATE TABLE [InsightArchive].[NWBBlackFridayPush2021] (
    [FanID]                     INT             NOT NULL,
    [Brand]                     VARCHAR (3)     NULL,
    [Marketable]                VARCHAR (10)    NULL,
    [Segment]                   VARCHAR (7)     NOT NULL,
    [ClubCashAvailable]         SMALLMONEY      NULL,
    [EmailVersion]              INT             NULL,
    [ControlFlag]               INT             NOT NULL,
    [SendDateClubCashAvailable] DECIMAL (32, 2) NULL
);

