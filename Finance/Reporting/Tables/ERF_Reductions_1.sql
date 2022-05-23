CREATE TABLE [Reporting].[ERF_Reductions] (
    [PublisherID]       SMALLINT        NOT NULL,
    [PaymentMethodID]   SMALLINT        NULL,
    [EarningSourceID]   INT             NULL,
    [PaymentCardType]   VARCHAR (40)    NULL,
    [EligibleType]      VARCHAR (32)    NOT NULL,
    [EligibleID]        INT             NOT NULL,
    [DeactivatedBand]   VARCHAR (50)    NULL,
    [DeactivatedBandID] SMALLINT        NOT NULL,
    [isCreditCardOnly]  BIT             NOT NULL,
    [MonthDate]         DATETIME        NULL,
    [EarningsAllocated] DECIMAL (38, 2) NULL,
    [BreakageAllocated] DECIMAL (38, 2) NULL
);

