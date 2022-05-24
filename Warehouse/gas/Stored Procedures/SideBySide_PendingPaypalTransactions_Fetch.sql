-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Used to load paypal pending transactions into the working area
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_PendingPaypalTransactions_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FileID
		, RowNum
		, BrandMIDID
		, BrandCombinationID
		, BankID
		, MID
		, Narrative
		, LocationAddress
		, LocationID
		, LocationCountry
		, MCC
		, MCCID
		, CardholderPresentData
		, CardholderPresentID
		, TranDate
		, CINID
		, PostStatus
		, Amount
		, IsRefund
		, IsOnline
		, InputModeID
		, PostStatusID
		, OriginatorID
		, SecondaryID
	FROM Staging.ConsumerTransactionPending
	WHERE BrandMIDID = 142652 --paypal

END