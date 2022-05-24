CREATE TABLE [Relational].[PartnerOffers_Base] (
    [PartnerID]           INT             NOT NULL,
    [PartnerName]         VARCHAR (100)   NULL,
    [OfferName]           NVARCHAR (200)  NOT NULL,
    [OfferID]             INT             NOT NULL,
    [CashBackRateText]    VARCHAR (10)    NULL,
    [CashBackRateNumeric] NUMERIC (16, 8) NULL,
    [Bank]                VARCHAR (7)     NULL,
    [ClubID]              INT             NULL,
    [StartDate]           DATETIME        NULL,
    [EndDate]             DATETIME        NULL,
    [AllSegments]         BIT             NULL,
    [HTMID]               INT             NULL,
    [CardType]            TINYINT         NULL
);

