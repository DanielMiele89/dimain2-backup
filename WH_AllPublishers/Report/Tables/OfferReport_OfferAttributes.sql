CREATE TABLE [Report].[OfferReport_OfferAttributes] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [StartDate]            DATETIME2 (7) NOT NULL,
    [EndDate]              DATETIME2 (7) NOT NULL,
    [ShopperSegmentTypeID] TINYINT       NULL,
    [OfferTypeID]          INT           NOT NULL,
    [CashbackRate]         REAL          NULL,
    [SpendStretch]         SMALLMONEY    NULL,
    [SpendStretchRate]     REAL          NULL,
    [PartnerID]            INT           NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

