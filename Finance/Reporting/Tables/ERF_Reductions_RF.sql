CREATE TABLE [Reporting].[ERF_Reductions_RF] (
    [PublisherID]     SMALLINT NOT NULL,
    [PaymentMethodID] INT      NULL,
    [EarningSourceID] INT      NULL,
    [ReductionTypeID] TINYINT  NOT NULL,
    [MonthDate]       DATETIME NULL,
    [earnings]        MONEY    NULL
);

