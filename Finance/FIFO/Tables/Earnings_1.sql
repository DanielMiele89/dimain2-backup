CREATE TABLE [FIFO].[Earnings] (
    [CustomerID]            INT            NOT NULL,
    [EligibleDate]          DATE           NULL,
    [TransactionID]         INT            NOT NULL,
    [CumulativeEarningFrom] DECIMAL (9, 2) NULL,
    [CumulativeEarningTo]   DECIMAL (9, 2) NULL,
    [Earning]               DECIMAL (9, 2) NULL,
    [EarningSourceID]       SMALLINT       NOT NULL,
    [PublisherID]           SMALLINT       NOT NULL,
    [PaymentCardID]         INT            NOT NULL,
    [PaymentMethodID]       SMALLINT       NOT NULL,
    [TranDate]              DATE           NOT NULL,
    [ActivationDays]        INT            NOT NULL,
    [CustomerEarningID]     INT            NULL,
    [PreviousCustomerID]    INT            NULL
);


GO
CREATE UNIQUE CLUSTERED INDEX [cx_Stuff]
    ON [FIFO].[Earnings]([CustomerID] ASC, [TranDate] ASC, [ActivationDays] ASC, [TransactionID] ASC) WITH (FILLFACTOR = 100);


GO
CREATE NONCLUSTERED INDEX [NIX]
    ON [FIFO].[Earnings]([CustomerID] ASC, [EligibleDate] ASC, [CumulativeEarningFrom] ASC, [CumulativeEarningTo] ASC)
    INCLUDE([CustomerEarningID]) WITH (FILLFACTOR = 90);


GO
CREATE NONCLUSTERED INDEX [UNIX]
    ON [FIFO].[Earnings]([CustomerID] ASC, [CustomerEarningID] ASC)
    INCLUDE([CumulativeEarningFrom], [CumulativeEarningTo]) WITH (FILLFACTOR = 90);

