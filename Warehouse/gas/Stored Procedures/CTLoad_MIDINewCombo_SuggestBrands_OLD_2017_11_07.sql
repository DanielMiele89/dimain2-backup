-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Clears new combo table for repopulation
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_SuggestBrands_OLD_2017_11_07]

AS
BEGIN

	SET NOCOUNT ON;

	--Prefix, MID, MCC, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 1
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MID, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 2
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MCC, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 3
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MID, MCC, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 4
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL

	--Prefix, MCC, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 5
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL

	--Prefix, MID, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 6
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL

	--Prefix, MCC
	INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 7
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MCCID = C.MCCID
	INNER JOIN Staging.BrandMatch bm ON C.BrandID = BM.BrandID AND M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND p.ComboID IS NULL

	--MID, MCC
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 8
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.MCCID = C.MCCID
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = c.BrandID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND c.BrandID != 943 -- do not match to paypal without a prefix match
	AND p.ComboID IS NULL

	--Prefix ONLY
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, bm.BrandID, 9
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Staging.BrandMatch bm ON M.Narrative LIKE BM.Narrative
	LEFT OUTER JOIN Staging.CTLoad_MIDINewCombo_PossibleBrands p ON M.ID = p.ComboID AND p.SuggestedBrandID = bm.BrandID
	WHERE p.ComboID IS NULL

	--LOAD TEXT MATCHES
	INSERT INTO Staging.CTLoad_MIDINewCombo_BrandMatch(ComboID, BrandMatchID, BrandID, BrandGroupID)
	SELECT DISTINCT M.ID, BM.BrandMatchID, BM.BrandID, B.BrandGroupID
	FROM Staging.CTLoad_MIDINewCombo M
	INNER JOIN Staging.BrandMatch bm ON M.Narrative LIKE BM.Narrative
	INNER JOIN Relational.Brand b ON bm.BrandID = b.BrandID

	--UPDATE INFORMATION IN MATCH TABLE
	EXEC gas.CTLoad_MIDINewCombo_UpdateMatchInfo

END
