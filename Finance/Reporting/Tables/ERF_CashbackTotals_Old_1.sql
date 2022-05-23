CREATE TABLE [Reporting].[ERF_CashbackTotals_Old] (
    [EarningSourceID] INT           NULL,
    [PaymentMethodID] INT           NULL,
    [PublisherID]     SMALLINT      NOT NULL,
    [Earnings]        MONEY         NULL,
    [ColumnName]      VARCHAR (50)  NULL,
    [ColumnID]        INT           NULL,
    [DisplayName]     VARCHAR (100) NULL,
    [PartnerName]     VARCHAR (100) NOT NULL,
    [PublisherName]   VARCHAR (100) NULL,
    [PaymentMethod]   VARCHAR (11)  NOT NULL,
    [FundingType]     VARCHAR (20)  NULL
);

