CREATE TABLE [Reporting].[ERF_CashbackTotals] (
    [PublisherID]      SMALLINT        NULL,
    [PaymentMethodID]  SMALLINT        NULL,
    [EarningSourceID]  INT             NULL,
    [PaymentCardType]  VARCHAR (40)    NULL,
    [isCreditCardOnly] BIT             NULL,
    [Earnings]         DECIMAL (38, 2) NULL,
    [ColumnName]       VARCHAR (50)    NULL,
    [ColumnID]         INT             NULL
);

