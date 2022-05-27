CREATE TABLE [Derived].[SchemeTransCompare_RewardBI] (
    [PublisherID]      INT   NOT NULL,
    [IronOfferID]      INT   NULL,
    [TranDate]         DATE  NOT NULL,
    [IsRetailerReport] BIT   NOT NULL,
    [IsRetailMonthly]  BIT   NOT NULL,
    [Spend]            MONEY NULL,
    [RetailerCashback] MONEY NULL,
    [Investment]       MONEY NULL
);

