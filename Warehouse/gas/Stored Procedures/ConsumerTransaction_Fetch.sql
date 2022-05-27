-- =============================================
-- Author:		JEA
-- Create date: 19/02/2014
-- Description:	Fetches those transactions that have been matched for the ConsumerTransaction table
-- =============================================
CREATE PROCEDURE [gas].[ConsumerTransaction_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FileID
		, RowNum
		, BrandCombinationID
		, SecondaryCombinationID
		, BankID
		, LocationID
		, CardholderPresentID
		, TranDate
		, CINID
		, Amount
		, IsRefund
		, IsOnline
		, CAST(0 AS TINYINT) AS InputModeID
		, PostStatusID
		, CAST(1 AS TINYINT) AS PaymentTypeID
	FROM Staging.CardTransactionHolding
	WHERE BrandCombinationID IS NOT NULL
	AND LocationID IS NOT NULL
	AND RequiresSecondaryID = 0

END
