-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE gas.CTLoad_OriginatorChangeFix 
	
AS
BEGIN

	SET NOCOUNT ON;

    CREATE TABLE #OriginatorChange(ID INT PRIMARY KEY, OriginatorID VARCHAR(11) NOT NULL, ConsumerCombinationID INT NULL)

	--get all new combinations where there is a match to an existing combination bar Originator of precisely one brand
	INSERT INTO #OriginatorChange(ID, OriginatorID)
	SELECT ID, OriginatorID
	FROM
	(
	SELECT c.ID, c.OriginatorID, COUNT(DISTINCT cc.BrandID) As BrandCount
	FROM Staging.CTLoad_MIDINewCombo c WITH (NOLOCK)
	INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) ON c.MID = cc.MID 
		AND c.Narrative= cc.Narrative 
		AND c.LocationCountry = cc.LocationCountry 
		AND c.MCCID = cc.MCCID
	GROUP BY c.ID, c.OriginatorID
	HAVING COUNT(DISTINCT cc.BrandID) = 1
	) O

	--pair the new combination with the lowest existing combination to which it matches
	UPDATE o
	SET ConsumerCombinationID = S.ConsumerCombinationID
	FROM #OriginatorChange o
	INNER JOIN 
		(SELECT c.ID, MIN(cc.ConsumerCombinationID) AS ConsumerCombinationID
			FROM  Staging.CTLoad_MIDINewCombo c WITH (NOLOCK)
			INNER JOIN #OriginatorChange o ON c.ID = o.ID
			INNER JOIN Relational.ConsumerCombination cc WITH (NOLOCK) ON c.MID = cc.MID 
				AND c.Narrative= cc.Narrative 
				AND c.LocationCountry = cc.LocationCountry 
				AND c.MCCID = cc.MCCID
			GROUP BY c.ID
		) s ON o.ID = s.ID

	--disable indexes for insert
	EXEC gas.CTLoad_ConsumerCombinationIndexes_Disable

	--insert as new combinations, copying all details of the existing combination except OriginatorID
	INSERT INTO Relational.ConsumerCombination(BrandID, MID, Narrative, LocationCountry, MCCID, OriginatorID, IsHighVariance, IsUKSpend, PaymentGatewayStatusID)
		SELECT cc.BrandID, cc.MID, cc.Narrative, cc.LocationCountry, cc.MCCID, o.OriginatorID, cc.IsHighVariance, cc.IsUKSpend, cc.PaymentGatewayStatusID
		FROM Relational.ConsumerCombination cc
		INNER JOIN #OriginatorChange o ON cc.ConsumerCombinationID = o.ConsumerCombinationID

	--rebuild indexes following insert
	EXEC gas.CTLoad_ConsumerCombinationIndexes_Rebuild

	--delete the inserted combos from the new combo list
	DELETE FROM c
	FROM Staging.CTLoad_MIDINewCombo c
	INNER JOIN #OriginatorChange o ON c.ID = o.ID

	DROP TABLE #OriginatorChange

END
