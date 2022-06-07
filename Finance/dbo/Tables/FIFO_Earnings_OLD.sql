CREATE TABLE [dbo].[FIFO_Earnings_OLD] (
    [EarningID]       INT     NOT NULL,
    [EarningTypeID]   TINYINT NULL,
    [EarningSourceID] INT     NOT NULL,
    [CustomerID]      INT     NOT NULL,
    [Earnings]        MONEY   NULL,
    [TranDate]        DATE    NULL
);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [dbo].[FIFO_Earnings_OLD]([CustomerID] ASC);


GO
CREATE NONCLUSTERED INDEX [NIX_EarningID]
    ON [dbo].[FIFO_Earnings_OLD]([EarningTypeID] ASC, [EarningID] ASC);

