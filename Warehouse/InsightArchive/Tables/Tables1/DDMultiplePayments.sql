CREATE TABLE [InsightArchive].[DDMultiplePayments] (
    [ID]                      INT        IDENTITY (1, 1) NOT NULL,
    [FanID]                   INT        NOT NULL,
    [DirectDebitOriginatorID] INT        NOT NULL,
    [PaymentCount]            FLOAT (53) NOT NULL,
    [CashbackTotal]           MONEY      NOT NULL,
    [SpendTotal]              MONEY      NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

