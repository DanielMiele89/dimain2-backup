-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Fetches all remaining holding transactions, now matched
-- =============================================
CREATE PROCEDURE [gas].[HoldingTransactions_FetchAll]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT FileID, RowNum, BrandMIDID, BankID, TerminalID, MID
	, Narrative, LocationAddress, LocationCountry, MCC
	, CardholderPresentData, TranDate, InDate, CINID, Amount
	, IsOnline, IsRefund -- 16/03/2013 JEA - Added
	FROM Staging.CardTransactionHolding
	ORDER BY FileID, RowNum
	
END