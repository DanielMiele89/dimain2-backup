
-- =============================================
-- Author:		JEA
-- Create date: 31/07/2013
-- Description: Retrieves details of new MIDs for Tesco
-- =============================================
CREATE PROCEDURE [MI].[RBSFundedNewMIDs_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	INSERT INTO MI.ConsumerCombination_Created(ConsumerCombinationID)
	SELECT ConsumerCombinationID
	FROM Relational.ConsumerCombination
	WHERE BrandMIDID IS NULL
	EXCEPT
	SELECT ConsumerCombinationID
	FROM mi.ConsumerCombination_Created

	CREATE TABLE #Combos(ConsumerCombinationID INT PRIMARY KEY)
	
	INSERT INTO #Combos(ConsumerCombinationID)
    SELECT c.ConsumerCombinationID 
	FROM mi.ConsumerCombination_Created c
	INNER JOIN relational.ConsumerCombination cc on c.ConsumerCombinationID = cc.ConsumerCombinationID
	INNER JOIN relational.brand b on cc.BrandID = b.BrandID
	LEFT OUTER JOIN (SELECT DISTINCT C.MID
						FROM Relational.ConsumerCombination c
						LEFT OUTER JOIN (select consumercombinationID
										FROM mi.ConsumerCombination_Created
										WHERE CheckDate IS NULL) cc on c.ConsumerCombinationID = cc.ConsumerCombinationID
						WHERE cc.ConsumerCombinationID IS NULL) m on cc.mid = m.mid
	WHERE b.BrandGroupID in (7) --JEA 31/07/2014 TESCO REMOVED
	AND cc.IsUKSpend = 1
	AND m.mid IS NULL

	UPDATE MI.ConsumerCombination_Created
	SET CheckDate = GETDATE()
	WHERE CheckDate IS NULL

	SELECT b.BrandID
		, b.BrandName AS Brand 
		, m.MID
		, m.Narrative
		, '0' AS CardholderPresentData
		, mcc.MCC
		, mcc.MCCDesc
	FROM #Combos c
	INNER JOIN Relational.ConsumerCombination m on c.ConsumerCombinationID = m.ConsumerCombinationID
	INNER JOIN Relational.Brand b on m.BrandID = b.BrandID
	INNER JOIN Relational.MCCList mcc on m.MCCID = mcc.MCCID

END