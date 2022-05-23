CREATE TABLE [Staging].[Temp_BreakageCustomers_OLD] (
    [CustomerID] INT NOT NULL
);


GO
CREATE CLUSTERED INDEX [CIX]
    ON [Staging].[Temp_BreakageCustomers_OLD]([CustomerID] ASC);

