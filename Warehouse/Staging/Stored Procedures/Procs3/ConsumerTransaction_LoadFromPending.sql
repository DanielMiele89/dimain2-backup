-- =============================================
-- Author:		JEA
-- Create date: 28/02/2014
-- Description:	Loads ConsumerTransaction with transactions no longer pending
-- =============================================
CREATE PROCEDURE Staging.ConsumerTransaction_LoadFromPending
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FileID, RowNum, BrandCombinationID, SecondaryID, BankID, LocationID, CardholderPresentData, TranDate, CINID, Amount, IsRefund, IsOnline, InputModeID, PostStatusID, CAST(1 AS TINYINT) AS PaymentTypeID
	FROM Staging.ConsumerTransactionPending
	WHERE BrandCombinationID IS NOT NULL
	AND LocationID IS NOT NULL

END