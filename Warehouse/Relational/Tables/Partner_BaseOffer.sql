CREATE TABLE [Relational].[Partner_BaseOffer] (
    [PartnerID]           INT             NOT NULL,
    [PartnerName]         VARCHAR (100)   NULL,
    [OfferName]           VARCHAR (100)   NULL,
    [SegmentCode]         CHAR (1)        NULL,
    [OfferID]             INT             NOT NULL,
    [CashBackRateText]    VARCHAR (11)    NULL,
    [CashBackRateNumeric] NUMERIC (10, 8) NULL,
    [StartDate]           DATETIME        NULL,
    [EndDate]             DATETIME        NULL,
    PRIMARY KEY CLUSTERED ([PartnerID] ASC, [OfferID] ASC)
);

