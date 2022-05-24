-- =============================================
-- Author:		JEA
-- Create date: 19/03/2014
-- Description:	Retrieves matched combinations
-- from the MIDI holding area
-- =============================================
CREATE PROCEDURE [gas].[CombinationsMIDIHolding_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FileID, RowNum, BankID, MID, Narrative, LocationAddress, LocationCountry, CardholderPresentData, TranDate
	, CINID, Amount, IsOnline, IsRefund, OriginatorID, MCCID, PostStatusID, LocationID
	, ConsumerCombinationID, SecondaryCombinationID, InputModeID, PaymentTypeID
	FROM Staging.CTLoad_MIDIHolding mh
	WHERE ConsumerCombinationID IS NOT NULL
	AND LocationID IS NOT NULL
	AND NOT EXISTS (SELECT 1
					FROM Relational.ConsumerTransactionHolding cth
					WHERE cth.FileID = mh.FileID
					AND cth.RowNum = mh.RowNum)


END