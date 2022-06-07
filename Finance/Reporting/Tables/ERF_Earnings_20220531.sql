CREATE TABLE [Reporting].[ERF_Earnings_20220531] (
    [PublisherID]       SMALLINT        NOT NULL,
    [PaymentMethodID]   SMALLINT        NOT NULL,
    [EarningSourceID]   SMALLINT        NOT NULL,
    [PaymentCardType]   VARCHAR (40)    NULL,
    [EligibleType]      VARCHAR (32)    NOT NULL,
    [EligibleID]        INT             NOT NULL,
    [DeactivatedBand]   VARCHAR (50)    NULL,
    [DeactivatedBandID] SMALLINT        NOT NULL,
    [isCreditCardOnly]  BIT             NOT NULL,
    [Earning]           DECIMAL (38, 2) NULL,
    [TranCount]         INT             NULL,
    [Spend]             DECIMAL (38, 2) NULL,
    [MonthDate]         DATETIME        NULL
);

