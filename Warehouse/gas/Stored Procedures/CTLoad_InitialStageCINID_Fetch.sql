-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Retrieves transactions from the holding table
-- =============================================
CREATE PROCEDURE gas.CTLoad_InitialStageCINID_Fetch
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
		, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID, ConsumerCombinationID
		, SecondaryCombinationID, InputModeID, PaymentTypeID
	FROM Staging.CTLoad_InitialStage
	WHERE CINID IS NOT NULL

END
