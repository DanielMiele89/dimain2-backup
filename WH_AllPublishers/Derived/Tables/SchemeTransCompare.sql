CREATE TABLE [Derived].[SchemeTransCompare] (
    [PublisherID]      INT      NOT NULL,
    [RetailerID]       INT      NOT NULL,
    [IronOfferID]      INT      NULL,
    [OutletID]         INT      NOT NULL,
    [FanID]            INT      NOT NULL,
    [Spend]            MONEY    NOT NULL,
    [RetailerCashback] MONEY    NOT NULL,
    [Investment]       MONEY    NOT NULL,
    [TranDate]         DATE     NOT NULL,
    [TranTime]         TIME (7) NOT NULL,
    [ID]               INT      NOT NULL,
    [IsRetailerReport] BIT      NOT NULL,
    [IsRetailMonthly]  BIT      NOT NULL
);

