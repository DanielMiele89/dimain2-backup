-- =============================================
-- Author:		JEA
-- Create date: 16/04/2014
-- Description:	Clears new combo table for repopulation
-- =============================================
CREATE PROCEDURE [gas].[CTLoad_MIDINewCombo_SuggestBrands_V2]

AS
BEGIN

	SET NOCOUNT ON;

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	--Prefix, MID, MCC, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 1
	FROM (
		   SELECT M.ID, M.MID, bm.BrandID, M.LocationCountry, M.MCCID, M.AcquirerID, m.OriginatorID 
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MID, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 2
	FROM (
		   SELECT M.ID, M.MID, bm.BrandID, M.LocationCountry, M.AcquirerID, m.OriginatorID 
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MCC, Country, Originator/Acquirer
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 3
	FROM (
		   SELECT M.ID, bm.BrandID, M.LocationCountry, M.MCCID, M.AcquirerID, m.OriginatorID 
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	LEFT OUTER JOIN MI.MOMCombinationAcquirer a ON M.AcquirerID = A.AcquirerID AND C.ConsumerCombinationID = A.ConsumerCombinationID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal
	AND ((M.OriginatorID = C.OriginatorID AND C.OriginatorID != '') OR a.AcquirerID IS NOT NULL)

	--Prefix, MID, MCC, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 4
	FROM (
		   SELECT M.ID, M.MID, bm.BrandID, M.LocationCountry, M.MCCID 
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal

	--Prefix, MCC, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 5
	FROM (
		   SELECT M.ID, bm.BrandID, M.LocationCountry, M.MCCID 
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.LocationCountry = c.LocationCountry
		AND M.MCCID = C.MCCID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal

	--Prefix, MID, Country
    INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 6
	FROM (
		   SELECT M.ID, M.MID, bm.BrandID, M.LocationCountry
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MID = C.MID
		AND M.LocationCountry = c.LocationCountry
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal

	--Prefix, MCC
	INSERT INTO Staging.CTLoad_MIDINewCombo_PossibleBrands(ComboID, SuggestedBrandID, MatchTypeID)
	SELECT DISTINCT M.ID, C.BrandID, 7
	FROM (
		   SELECT M.ID, bm.BrandID, M.MCCID
		   FROM Staging.CTLoad_MIDINewCombo M
		   INNER JOIN Staging.BrandMatch bm 
				  ON  M.Narrative LIKE BM.Narrative
		   WHERE NOT EXISTS (SELECT 1 FROM Staging.CTLoad_MIDINewCombo_PossibleBrands p WHERE p.ComboID = m.ID AND p.SuggestedBrandID = bm.BrandID)
	) M
	INNER JOIN Relational.ConsumerCombination C
		ON M.MCCID = C.MCCID
	WHERE c.PaymentGatewayStatusID != 1 --exclude non-individuated paypal

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
