
-- =============================================
-- Author:		JEA
-- Create date: 19/04/2014
-- Description:	Clears new combo table for repopulation
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_UpdateMatchInfo]

AS
BEGIN

	SET NOCOUNT ON;

	/* HIGH CONFIDENCE UNBRANDED
		Where no match with text patterns or combos has been found and unbranded probability is 90%+ by data mining
	*/
	UPDATE staging.CTLoad_MIDINewCombo
	SET MatchCount = 1
		, SuggestedBrandID = 944
		, BrandProbability = d.Probability
		, MatchType = 12
	FROM Staging.CTLoad_MIDINewCombo c
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_BrandMatch b on c.ID = b.ComboID
	INNER JOIN (SELECT ComboID, Probability
					FROM Staging.CTLoad_MIDINewCombo_DataMining 
					WHERE SuggestedBrandID = 944
					AND ProbabilityOrdinal = 1
					AND Probability >= 0.9) D ON C.ID = D.ComboID
	WHERE b.ComboID IS NULL
	AND NOT (Narrative LIKE 'PAYPAL%' OR Narrative LIKE 'PP*%')

	/* HIGH CONFIDENCE CORRECT BRAND
		Where matching and data mining agree on the brand identity with high probability
	*/
	UPDATE Staging.CTLoad_MIDINewCombo_PossibleBrands 
		SET BrandProbability = d.Probability
	FROM Staging.CTLoad_MIDINewCombo_DataMining d
		INNER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON d.ComboID = P.ComboID AND d.SuggestedBrandID = p.SuggestedBrandID
	WHERE d.SuggestedBrandID != 944

	UPDATE Staging.CTLoad_MIDINewCombo_PossibleBrands
		SET MatchTypeID = 0
	WHERE BrandProbability >= 0.5
		AND MatchTypeID <= 4

	INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID, BrandProbability)
	SELECT d.ComboID, d.SuggestedBrandID, 14, d.Probability
	FROM Staging.CTLoad_MIDINewCombo_DataMining d
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON d.ComboID = P.ComboID AND d.SuggestedBrandID = p.SuggestedBrandID
	WHERE D.Probability >= 0.5
	AND d.SuggestedBrandID != 944
	AND p.ComboID IS NULL

	UPDATE Staging.CTLoad_MIDINewCombo
		SET SuggestedBrandID = p.SuggestedBrandID
		, MatchType = p.MatchTypeID
		, BrandProbability = p.BrandProbability
	FROM Staging.CTLoad_MIDINewCombo C
	INNER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON C.ID = P.ComboID
	INNER JOIN (SELECT ComboID, MIN(MatchTypeID) AS MatchTypeID
				FROM Staging.CTLoad_MIDINewCombo_PossibleBrands
				GROUP BY ComboID
				) m ON p.ComboID = m.ComboID and p.MatchTypeID = m.MatchTypeID
	WHERE c.SuggestedBrandID IS NULL

	UPDATE Staging.CTLoad_MIDINewCombo
		SET MatchCount = p.MatchCount
	FROM Staging.CTLoad_MIDINewCombo C
	INNER JOIN (SELECT ComboID, COUNT(1) AS MatchCount
				FROM Staging.CTLoad_MIDINewCombo_PossibleBrands
				WHERE SuggestedBrandID != 943
				AND SuggestedBrandID != 944
				GROUP BY ComboID
				HAVING COUNT(1) > 1) p ON C.ID = p.ComboID
	WHERE SuggestedBrandID != 943
		AND SuggestedBrandID != 944

	--match paypal
	UPDATE Staging.CTLoad_MIDINewCombo
	SET SuggestedBrandID = 943
		, MatchType = 10
	WHERE (Narrative LIKE 'PAYPAL%') --OR Narrative LIKE 'PP*%')
	AND (SuggestedBrandID IS NULL OR SuggestedBrandID = 944)

	----Mark the rest as unbranded
	UPDATE Staging.CTLoad_MIDINewCombo
	SET SuggestedBrandID = 944
		, MatchType = 11
	WHERE SuggestedBrandID IS NULL

	--CHANGE SUGGESTED BRAND IDs ACCORDING TO EXCEPTIONS

	UPDATE m
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Staging.CTLoad_MIDINewCombo m
	INNER JOIN Staging.MIDIBrandChange_MCC mc
		ON m.SuggestedBrandID = mc.BrandIDInitial
		AND m.MCCID = mc.MCCID

	UPDATE m
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Staging.CTLoad_MIDINewCombo m
	INNER JOIN Staging.MIDIBrandChange_Narrative mc
		ON m.SuggestedBrandID = mc.BrandIDInitial
		AND m.Narrative LIKE mc.Narrative

END

