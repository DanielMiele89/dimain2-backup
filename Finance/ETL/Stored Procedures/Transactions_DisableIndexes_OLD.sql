CREATE PROCEDURE ETL.[Transactions_DisableIndexes_OLD]
AS
BEGIN
	ALTER INDEX [NIX_CustomerID] ON [dbo].[Transactions]	DISABLE
	ALTER INDEX [NIX_Earnings] ON [dbo].[Transactions]		DISABLE
	ALTER INDEX [NIX_TranDate] ON [dbo].[Transactions]		DISABLE
	ALTER INDEX NIX_CreatedDateTime ON [dbo].[Transactions]		DISABLE
	ALTER INDEX [NIX_FIFO_Breakage] ON [dbo].[Transactions]		DISABLE

	ALTER TABLE dbo.Transactions NOCHECK CONSTRAINT ALL

END