CREATE TABLE [Staging].[BaseOffer] (
    [PartnerID]           INT             NOT NULL,
    [PartnerName]         VARCHAR (100)   NULL,
    [OfferName]           VARCHAR (100)   NULL,
    [SegmentCode]         CHAR (1)        NULL,
    [OfferID]             INT             NOT NULL,
    [CashBackRateText]    VARCHAR (10)    NULL,
    [CashBackRateNumeric] NUMERIC (10, 8) NULL
);

