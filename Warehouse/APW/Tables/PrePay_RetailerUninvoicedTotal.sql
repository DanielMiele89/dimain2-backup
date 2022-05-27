CREATE TABLE [APW].[PrePay_RetailerUninvoicedTotal] (
    [ID]            INT   IDENTITY (1, 1) NOT NULL,
    [RetailerID]    INT   NOT NULL,
    [BalanceAmount] MONEY NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);

