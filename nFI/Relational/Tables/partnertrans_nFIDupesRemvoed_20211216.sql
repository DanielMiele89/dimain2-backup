CREATE TABLE [Relational].[partnertrans_nFIDupesRemvoed_20211216] (
    [ID]                  INT        IDENTITY (1, 1) NOT NULL,
    [MatchID]             INT        NULL,
    [FanID]               INT        NOT NULL,
    [PartnerID]           SMALLINT   NULL,
    [OutletID]            INT        NULL,
    [TransactionAmount]   SMALLMONEY NOT NULL,
    [TransactionDate]     DATETIME   NULL,
    [AddedDate]           DATE       NULL,
    [CashbackEarned]      SMALLMONEY NULL,
    [CommissionChargable] SMALLMONEY NULL,
    [IronOfferID]         INT        NULL
);

