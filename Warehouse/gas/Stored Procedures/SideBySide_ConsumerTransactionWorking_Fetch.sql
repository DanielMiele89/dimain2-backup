-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Retrieves contents of transaction working table
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ConsumerTransactionWorking_Fetch]
	
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
		, MCCID
		, CardholderPresentID
		, TranDate
		, CINID
		, Amount
		, IsRefund
		, IsOnline
		, 0 AS InputModeID
		, PostStatusID
		, OriginatorID
		, SecondaryID
		, 1 AS PaymentTypeID
		, RequiresSecondaryID
	FROM Staging.ConsumerTransactionWorking

END
