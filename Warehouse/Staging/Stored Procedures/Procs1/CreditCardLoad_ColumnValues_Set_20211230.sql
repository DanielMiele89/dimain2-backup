-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>

------------------------------------------------------------------------------
--Modification History

--Jason Shipp 29/05/2019
	-- Added update of statistics on staging tables to avoid silly execution plans (Ie. multiple full table scans)

-- =============================================
CREATE PROCEDURE [Staging].[CreditCardLoad_ColumnValues_Set_20211230]
	
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

	SELECT DISTINCT i.CIN
	INTO #NewCINs
	FROM Staging.CreditCardLoad_InitialStage i
	LEFT OUTER JOIN Relational.CINList c ON i.CIN = c.CIN
	WHERE c.CIN IS NULL

	INSERT INTO Relational.CINList(CIN)
	SELECT CIN
	FROM #NewCINs

	UPDATE i SET CINID = c.CINID
	FROM staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.CINList c ON i.CIN = c.CIN

	SELECT DISTINCT i.LocationCountry, i.PostCode
	INTO #NewPostCodes
	FROM staging.CreditCardLoad_InitialStage i
	LEFT OUTER JOIN Relational.CreditCardPostCode p ON i.LocationCountry = p.LocationCountry AND i.PostCode = p.PostCode
	WHERE P.LocationID IS NULL

	INSERT INTO Relational.CreditCardPostCode(LocationCountry, PostCode)
	SELECT LocationCountry, PostCode
	FROM #NewPostCodes

	UPDATE i SET LocationID = p.LocationID
	FROM staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.CreditCardPostCode p ON i.LocationCountry = p.LocationCountry and i.PostCode = p.PostCode

	SELECT DISTINCT i.MCC
	INTO #NewMCCs
	FROM staging.CreditCardLoad_InitialStage i
	LEFT OUTER JOIN Relational.MCCList m ON i.MCC = M.MCC
	WHERE m.MCC IS NULL

	INSERT INTO Relational.MCCList(MCC, MCCGroup, MCCCategory, MCCDesc, SectorID)
	SELECT MCC, '', '', '', 1
	FROM #NewMCCs

	UPDATE i SET MCCID = m.MCCID
	FROM staging.CreditCardLoad_InitialStage i
	INNER JOIN Relational.MCCList m ON i.MCC = m.MCC

	UPDATE staging.CreditCardLoad_InitialStage
	SET MID = LTRIM(RTRIM(MID))
		, Narrative = LTRIM(RTRIM(Narrative))
		, LocationCountry = LTRIM(RTRIM(LocationCountry))

	UPDATE staging.CreditCardLoad_InitialStage
	SET Narrative = REPLACE(narrative, '"', '')

END
