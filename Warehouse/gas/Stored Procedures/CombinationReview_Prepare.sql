-- =============================================
-- Author:		JEA
-- Create date: 08/11/2012
-- Description:	Used by Merchant Processing Module.
-- Populates the CombinationReview table ready
-- for the operation of the MIDI Intervention Module
-- =============================================
CREATE PROCEDURE [gas].[CombinationReview_Prepare]
	
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO Staging.CombinationReview(MID, Narrative)
	SELECT MID, Narrative
	FROM Staging.CardTransactionHoldingNoBrandMIDID
	EXCEPT
	SELECT MID, Narrative
	FROM Staging.CombinationReview

	UPDATE Staging.CombinationReview
	SET LocationAddress = c.LocationAddress
	, LocationCountry = c.LocationCountry
	, MCC = c.MCC
	FROM Staging.CombinationReview r
	INNER JOIN Staging.CardTransactionHoldingNoBrandMIDID c
		ON r.MID = c.MID and r.Narrative = c.Narrative
	WHERE r.LocationAddress IS NULL

	--MID and prefix matches
	UPDATE Staging.CombinationReview SET SuggestedBrandID = BM.BrandID, Confidence = 'MnP'
	FROM Staging.CombinationReview M
	INNER JOIN Staging.Combination C ON M.MID = C.MID AND m.LocationCountry = c.LocationCountry
	INNER JOIN Relational.BrandMID BM ON C.BrandMIDID = BM.BrandMIDID
	INNER JOIN Staging.BrandMatch BMA ON bm.BrandID = bma.BrandID AND M.Narrative LIKE bma.Narrative
	WHERE M.SuggestedBrandID IS NULL

	--MID only matches
	UPDATE Staging.CombinationReview SET SuggestedBrandID = BM.BrandID, Confidence = 'MO'
	FROM Staging.CombinationReview M
	INNER JOIN Staging.Combination C ON M.MID = C.MID AND m.LocationCountry = c.LocationCountry
	INNER JOIN Relational.BrandMID BM ON C.BrandMIDID = BM.BrandMIDID
	WHERE M.SuggestedBrandID IS NULL
	AND BM.BrandID != 944  --do not suggest an unbranded match for any combination where a pattern fits

	--Prefix only matches
	UPDATE Staging.CombinationReview SET SuggestedBrandID = BMA.BrandID, Confidence = 'PO'
	FROM Staging.CombinationReview M
	INNER JOIN Staging.BrandMatch BMA ON M.Narrative LIKE bma.Narrative
	WHERE M.SuggestedBrandID IS NULL

	--Mark the rest as not of interest by default
	UPDATE Staging.CombinationReview SET SuggestedBrandID = 944, Confidence = 'UNK'
	WHERE SuggestedBrandID IS NULL
	
	--Update card transaction statistics
	--UPDATE STATISTICS Relational.CardTransaction
 --   UPDATE STATISTICS Relational.BrandMID
	
END
