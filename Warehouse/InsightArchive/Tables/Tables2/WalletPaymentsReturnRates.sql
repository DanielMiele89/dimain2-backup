CREATE TABLE [InsightArchive].[WalletPaymentsReturnRates] (
    [PaypalActuals]                MONEY            NULL,
    [CurveActuals]                 MONEY            NULL,
    [KlarnaActuals]                MONEY            NULL,
    [Spend]                        MONEY            NULL,
    [Purchases]                    MONEY            NULL,
    [Returns]                      MONEY            NULL,
    [PaypalKlarnaCRVReturnRate]    NUMERIC (38, 17) NULL,
    [NonPaypalKlarnaCRVReturnRate] NUMERIC (38, 17) NULL,
    [ReturnRate]                   NUMERIC (38, 17) NULL,
    [WalletPayments]               NUMERIC (38, 17) NULL,
    [BrandName]                    VARCHAR (50)     NOT NULL,
    [TransactionDate]              DATETIME         NULL
);

