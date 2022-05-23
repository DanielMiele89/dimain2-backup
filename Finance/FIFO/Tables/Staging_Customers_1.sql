CREATE TABLE [FIFO].[Staging_Customers] (
    [rw]         INT IDENTITY (1, 1) NOT NULL,
    [CustomerID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [FIFO].[Staging_Customers]([rw] DESC) WITH (FILLFACTOR = 90);

