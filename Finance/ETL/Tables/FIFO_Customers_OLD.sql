CREATE TABLE [ETL].[FIFO_Customers_OLD] (
    [CustomerID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [ETL].[FIFO_Customers_OLD]([CustomerID] ASC);

