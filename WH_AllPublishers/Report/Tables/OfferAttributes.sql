CREATE TABLE [Report].[OfferAttributes] (
    [ID]                   INT           IDENTITY (1, 1) NOT NULL,
    [StartDate]            DATETIME2 (7) NOT NULL,
    [EndDate]              DATETIME2 (7) NOT NULL,
    [ShopperSegmentTypeID] SMALLINT      NULL,
    [OfferTypeID]          INT           NOT NULL,
    [CashbackRate]         REAL          NULL,
    [SpendStretch]         SMALLMONEY    NULL,
    [SpendStretchRate]     REAL          NULL,
    [PartnerID]            INT           NOT NULL,
    CONSTRAINT [PK__OfferAtt__3214EC2750D00165] PRIMARY KEY CLUSTERED ([ID] ASC)
);

