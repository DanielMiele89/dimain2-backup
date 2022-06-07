CREATE PROCEDURE ETL.[Transactions_RebuildIndexes_OLD]
AS
BEGIN
	ALTER TABLE dbo.Transactions WITH CHECK CHECK CONSTRAINT ALL

	ALTER INDEX [NIX_CustomerID] ON [dbo].[Transactions]	REBUILD
	ALTER INDEX [NIX_Earnings] ON [dbo].[Transactions]		REBUILD
	ALTER INDEX [NIX_TranDate] ON [dbo].[Transactions]		REBUILD
	ALTER INDEX NIX_CreatedDateTime ON [dbo].[Transactions]		REBUILD
	ALTER INDEX [NIX_FIFO_Breakage] ON [dbo].[Transactions]		REBUILD

END
