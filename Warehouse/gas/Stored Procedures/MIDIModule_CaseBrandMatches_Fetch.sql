-- =============================================
-- Author:		JEA
-- Create date: 20/06/2014
-- =============================================
CREATE PROCEDURE gas.MIDIModule_CaseBrandMatches_Fetch 
	(
		@CombinationReviewID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT b.BrandID
		, b.BrandName AS Brand
		, p.BrandProbability AS Probability
		, bc.MatchType
	FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p
		INNER JOIN Staging.CTLoad_BrandSuggestConfidence bc ON p.MatchTypeID = bc.MatchTypeID
		INNER JOIN Relational.Brand b ON p.SuggestedBrandID = b.BrandID
	WHERE p.ComboID = @CombinationReviewID
	ORDER BY bc.MatchTypeID

END
