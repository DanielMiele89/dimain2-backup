-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Fetches unmatched transactions from the holding area
-- =============================================
CREATE PROCEDURE [gas].[HoldingUnmatchedTransactions_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT FileID, RowNum, BankIDString, BankID, TerminalID, MID
		, Narrative, LocationAddress, LocationCountry, MCC, CardholderPresentData
		, TranDateString, TranDate, InDate, PaymentCardID, CIN, CINID, Amount
		, IsOnline, IsRefund -- 16/03/2013 JEA - Added
	FROM Staging.CardTransactionHolding
	WHERE BrandMIDID IS NULL
	
END
