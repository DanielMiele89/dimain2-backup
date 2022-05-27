-- =============================================
-- Author:		JEA
-- Create date: 15/07/2013
-- Description:	Used by Merchant Processing Module.
-- Fetches all remaining holding transactions, now matched
-- =============================================
 CREATE PROCEDURE [gas].[HoldingTransactions_Rainbow_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT FileID, RowNum, BrandMIDID, BankID, TerminalID, MID
	, Narrative, LocationAddress, LocationCountry, MCC
	, CardholderPresentData, TranDate, InDate, CINID, Amount
	FROM Staging.CardTransactionHolding
	WHERE BankID > 2
	ORDER BY FileID, RowNum
	
END
