-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>

------------------------------------------------------------------------------
--Modification History

--Jason Shipp 29/05/2019
	-- Added update of statistics on staging tables to avoid silly execution plans (Ie. multiple full table scans)

-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_ColumnValues_Set]
	
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE STATISTICS Staging.CreditCardLoad_InitialStage -- Jason Shipp 29/05/2019
	UPDATE STATISTICS Relational.CreditCardPostCode -- Jason Shipp 29/05/2019

    UPDATE Staging.CreditCardLoad_InitialStage
	SET CardholderPresentMC = '9'
	WHERE CardholderPresentMC = ''

	UPDATE i SET CIN = c.SourceUID
	FROM Staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.Customer c ON i.FanID = c.FanID
	WHERE CIN = ''

	--SELECT DISTINCT i.CIN
	--INTO #NewCINs
	--FROM Staging.CreditCardLoad_InitialStage i
	--LEFT OUTER JOIN Relational.CINList c 
	--	ON i.CIN = c.CIN
	--WHERE c.CIN IS NULL

	--INSERT INTO Relational.CINList(CIN)
	--SELECT CIN
	--FROM #NewCINs

	INSERT INTO Relational.CINList
		(CIN)
	SELECT DISTINCT 
		i.CIN
	FROM Staging.CreditCardLoad_InitialStage i
	WHERE NOT EXISTS (
		SELECT 1 FROM Relational.CINList c 
		WHERE i.CIN = c.CIN)
	ORDER BY i.CIN

	UPDATE i SET CINID = c.CINID
	FROM staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.CINList c 
		ON i.CIN = c.CIN

	--SELECT DISTINCT i.LocationCountry, i.PostCode
	--INTO #NewPostCodes
	--FROM staging.CreditCardLoad_InitialStage i
	--LEFT OUTER JOIN Relational.CreditCardPostCode p 
	--	ON i.LocationCountry = p.LocationCountry AND i.PostCode = p.PostCode
	--WHERE P.LocationID IS NULL

	--INSERT INTO Relational.CreditCardPostCode (LocationCountry, PostCode)
	--SELECT LocationCountry, PostCode
	--FROM #NewPostCodes

	INSERT INTO Relational.CreditCardPostCode 
		(LocationCountry, PostCode)
	SELECT DISTINCT 
		i.LocationCountry, i.PostCode
	FROM staging.CreditCardLoad_InitialStage i
	WHERE NOT EXISTS (	
		SELECT 1 FROM Relational.CreditCardPostCode p 
		WHERE i.LocationCountry = p.LocationCountry AND i.PostCode = p.PostCode)
	ORDER BY i.LocationCountry, i.PostCode

	UPDATE i SET LocationID = p.LocationID
	FROM staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.CreditCardPostCode p 
		ON i.LocationCountry = p.LocationCountry and i.PostCode = p.PostCode

	--SELECT DISTINCT i.MCC
	--INTO #NewMCCs
	--FROM staging.CreditCardLoad_InitialStage i
	--LEFT OUTER JOIN Relational.MCCList m 
	--	ON i.MCC = M.MCC
	--WHERE m.MCC IS NULL

	--INSERT INTO Relational.MCCList(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	--SELECT MCC, '', '', '', 1
	--FROM #NewMCCs

	INSERT INTO Relational.MCCList
		(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT DISTINCT 
		i.MCC, '', '', '', 1
	FROM staging.CreditCardLoad_InitialStage i
	WHERE NOT EXISTS (SELECT 1 FROM Relational.MCCList m 
		WHERE i.MCC = M.MCC)

	UPDATE i SET MCCID = m.MCCID
	FROM staging.CreditCardLoad_InitialStage i
	CROSS APPLY ( -- non-deterministic if MCC = '', there are 83 matching rows 
		SELECT TOP(1) m.MCCID 
		FROM Relational.MCCList m 
		WHERE i.MCC = m.MCC
		ORDER BY m.MCCID DESC
	) m

	UPDATE staging.CreditCardLoad_InitialStage
	SET MID = LTRIM(RTRIM(MID))
		, Narrative = REPLACE(LTRIM(RTRIM(Narrative)), '"', '')
		, LocationCountry = LTRIM(RTRIM(LocationCountry))

	--UPDATE staging.CreditCardLoad_InitialStage
	--SET Narrative = REPLACE(LTRIM(RTRIM(Narrative)), '"', '')

END