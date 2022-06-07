CREATE TABLE [dbo].[EarningsRated_HR] (
    [CustomerID]      INT        NOT NULL,
    [PublisherID]     INT        NOT NULL,
    [EarningsPin]     BIGINT     NOT NULL,
    [EarningSourceID] SMALLINT   NULL,
    [TranDate]        DATE       NULL,
    [TransactionID]   INT        NULL,
    [Earnings]        SMALLMONEY NULL,
    [E_from]          MONEY      NULL,
    [E_to]            MONEY      NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cx_Stuff]
    ON [dbo].[EarningsRated_HR]([CustomerID] ASC, [TranDate] ASC, [E_from] ASC) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE UNIQUE NONCLUSTERED INDEX [uix_Stuff]
    ON [dbo].[EarningsRated_HR]([CustomerID] ASC, [EarningsPin] ASC)
    INCLUDE([E_to]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

