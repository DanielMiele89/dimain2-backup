CREATE TABLE [Reporting].[ERF_CashbackTotals2] (
    [PublisherID]      SMALLINT        NOT NULL,
    [PaymentMethodID]  SMALLINT        NULL,
    [EarningSourceID]  INT             NULL,
    [PaymentCardType]  VARCHAR (40)    NULL,
    [isCreditCardOnly] BIT             NOT NULL,
    [Earnings]         DECIMAL (38, 2) NULL,
    [MonthDate]        DATETIME        NULL,
    [ColumnName]       VARCHAR (50)    NULL,
    [ColumnID]         INT             NULL,
    [DisplayName]      VARCHAR (100)   NOT NULL,
    [PartnerName]      VARCHAR (100)   NOT NULL,
    [PublisherName]    VARCHAR (100)   NULL,
    [PaymentMethod]    VARCHAR (40)    NOT NULL,
    [FundingType]      VARCHAR (20)    NOT NULL
);

