-- =============================================
-- Author:		JEA
-- Create date: 07/11/2012
-- Description:	Used by Merchant Processing Module.
-- Selects matched transactions that were previously unmatched
-- =============================================
CREATE PROCEDURE [gas].[CardTransactionPreviouslyUnmatched_Fetch]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT FileID, RowNum, BrandMIDID, BankID
	, Narrative, LocationAddress, LocationCountry, MCC
	, CardholderPresentData, TranDate, InDate, CINID, Amount
	, IsOnline, IsRefund -- 16/03/2013 JEA Added
	FROM Staging.CardTransactionHoldingNoBrandMIDID
	WHERE NOT BrandMIDID IS NULL
	ORDER BY FileID, RowNum

END