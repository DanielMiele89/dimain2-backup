CREATE TABLE [Derived].[SchemeTrans_Agg_RF] (
    [PublisherID]      INT   NOT NULL,
    [RetailerID]       INT   NOT NULL,
    [TranDate]         DATE  NULL,
    [IsRetailerReport] BIT   NOT NULL,
    [Tranactions]      INT   NULL,
    [Spend]            MONEY NULL,
    [Investment]       MONEY NULL
);

