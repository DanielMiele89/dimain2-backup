-- =============================================
-- Author:		JEA
-- Create date: 17/02/2014
-- Description:	Retrieves transactions lacking a CombinationID
--or location ID following the conventional matching process
-- =============================================
CREATE PROCEDURE [gas].[ConsumerTransactionPending_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT FileID,
		RowNum,
		BrandMIDID,
		BrandCombinationID,
		BankID,
		MID,
		Narrative,
		LocationAddress,
		LocationID,
		LocationCountry,
		MCC,
		MCCID,
		CardholderPresentData,
		CardholderPresentID,
		TranDate,
		CINID,
		PostStatus,
		Amount,
		IsRefund,
		IsOnline,
		CAST(0 AS TINYINT) AS InputModeID,
		PostStatusID,
		OriginatorID,
		SecondaryCombinationID,
		CAST(1 AS TINYINT) AS PaymentTypeID,
		RequiresSecondaryID
	FROM Staging.CardTransactionHolding
	WHERE (BrandCombinationID IS NULL 
		OR LocationID IS NULL
		OR RequiresSecondaryID = 1)
		AND CINID IS NOT NULL
    
END
