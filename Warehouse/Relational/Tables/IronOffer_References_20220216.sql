CREATE TABLE [Relational].[IronOffer_References_20220216] (
    [ID]                   INT        NOT NULL,
    [IronOfferID]          INT        NOT NULL,
    [ClubID]               INT        NOT NULL,
    [ironoffercyclesid]    INT        NOT NULL,
    [ShopperSegmentTypeID] SMALLINT   NULL,
    [OfferTypeID]          INT        NOT NULL,
    [CashbackRate]         REAL       NULL,
    [SpendStretch]         SMALLMONEY NULL,
    [SpendStretchRate]     REAL       NULL
);

