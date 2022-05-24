-- =============================================
-- Author:		JEA
-- Create date: 06/03/2014
-- Description:	Loads transactions from missing location area
-- =============================================
CREATE PROCEDURE gas.SideBySide_LocationSetTransactions_Fetch 
	
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
		, CAST(0 AS TINYINT) AS InputModeID
		, PostStatusID
		, OriginatorID
		, SecondaryID
		, CAST(1 AS TINYINT) AS PaymentTypeID
	FROM Staging.ConsumerTransactionLocationMissing

END
