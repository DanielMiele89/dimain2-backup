
-- =============================================
-- Author:		JEA
-- Create date: 19/04/2014
-- Description:	Clears new combo table for repopulation

-- Change log:
-- RF 2018-10-25: Marking unbranded as 944 moved before marking as PayPal to reduce amount of were clauses when marking PayPall as 943
--				  Condition to update iZettle MIDs to 1293 where unbranded or branded on MID, MCCID only

-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_UpdateMatchInfo_V2]

AS
BEGIN

	SET NOCOUNT ON;

	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MinMatchType') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	Select ID
		 , ComboID
		 , SuggestedBrandID
		 , MatchTypeID
		 , BrandProbability
	Into #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType
	From (Select ID
			   , ComboID
			   , SuggestedBrandID
			   , MatchTypeID
			   , BrandProbability
			   , Min(MatchTypeID) Over (Partition by ComboID) as MinMatchTypeID
		  FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands pb) mpb
	Where MatchTypeID = MinMatchTypeID

	UPDATE mnc
	SET SuggestedBrandID = pbm.SuggestedBrandID
	  , MatchType = pbm.MatchTypeID
	  , BrandProbability = pbm.BrandProbability
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MinMatchType pbm
		ON mnc.ID = pbm.ComboID
	WHERE mnc.SuggestedBrandID IS NULL

	If Object_ID('tempdb..#CTLoad_MIDINewCombo_PossibleBrands_MatchCount') Is Not Null Drop Table #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	Select ComboID
		 , COUNT(1) AS MatchCount
	Into #CTLoad_MIDINewCombo_PossibleBrands_MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_PossibleBrands
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944
	GROUP BY ComboID
	HAVING COUNT(1) > 1

	UPDATE mnc
	SET MatchCount = pbmc.MatchCount
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN #CTLoad_MIDINewCombo_PossibleBrands_MatchCount pbmc
		ON mnc.ID = pbmc.ComboID
	WHERE SuggestedBrandID != 943
	AND SuggestedBrandID != 944

	
	----Mark the rest as unbranded
	UPDATE mnc
	SET SuggestedBrandID = 944
	  , MatchType = 11
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE SuggestedBrandID IS NULL

	--match paypal
	UPDATE mnc
	SET SuggestedBrandID = 943
	  , MatchType = 10
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	WHERE (Narrative LIKE '%PAYPAL%') -- OR Narrative LIKE 'PP*%')
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--match iZettle
	UPDATE Warehouse.Staging.CTLoad_MIDINewCombo_v2
	SET SuggestedBrandID = 1293
	  , MatchType = 14
	WHERE Narrative Like '%IZ *%'
	AND (SuggestedBrandID = 944 Or MatchType = 9)

	--CHANGE SUGGESTED BRAND IDs ACCORDING TO EXCEPTIONS

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_MCC mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.MCCID = mc.MCCID

	UPDATE mnc
	SET SuggestedBrandID = mc.BrandIDChange
	FROM Warehouse.Staging.CTLoad_MIDINewCombo_v2 mnc
	INNER JOIN Staging.MIDIBrandChange_Narrative mc
		ON mnc.SuggestedBrandID = mc.BrandIDInitial
		AND mnc.Narrative_Cleaned LIKE mc.Narrative

END