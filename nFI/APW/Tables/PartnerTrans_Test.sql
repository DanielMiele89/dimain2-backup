CREATE TABLE [APW].[PartnerTrans_Test] (
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
    [IronOfferID]         INT        NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

