CREATE TABLE [InsightArchive].[CurrysData20160624] (
    [MatchID]         INT            NOT NULL,
    [MerchantID]      NVARCHAR (19)  NOT NULL,
    [Store]           NVARCHAR (20)  NULL,
    [Date]            VARCHAR (6)    NULL,
    [AmountSpent]     SMALLMONEY     NOT NULL,
    [OfferPercentage] INT            NULL,
    [CashbackEarned]  MONEY          NULL,
    [CommissionRate]  FLOAT (53)     NULL,
    [NetAmount]       MONEY          NULL,
    [VatAmount]       SMALLMONEY     NULL,
    [GrossAmount]     SMALLMONEY     NULL,
    [PartialPostcode] VARCHAR (4)    NULL,
    [HashedEmail]     NVARCHAR (MAX) NULL
);

