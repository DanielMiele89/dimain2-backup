-- =============================================
-- Author:		JEA
-- Create date: 06/07/2017
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[RetailerPotentialValue_ConsumerTrans_Fetch]
	(
		@StartDate DATE
		, @EndDate DATE
	)
AS
BEGIN

	SET NOCOUNT ON;

    CREATE TABLE #Combos(ConsumerCombinationID INT, RetailerID INT)
	CREATE CLUSTERED INDEX CIX_CCID ON #Combos (ConsumerCombinationID)

	CREATE TABLE #CINs(CINID int primary key)

	INSERT INTO #Combos(ConsumerCombinationID, RetailerID)
	SELECT cc.ConsumerCombinationID, b.RetailerID
	FROM Relational.ConsumerCombination cc
	INNER JOIN APW.RetailerPotentialValue_Brand b ON cc.BrandID = b.BrandID

	INSERT INTO #CINs(CINID)
	SELECT cl.CINID
	FROM Relational.CINList CL
	INNER JOIN Relational.Customer c on cl.cin = c.SourceUID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.fanID = d.fanid
	WHERE c.currentlyactive = 1
	AND d.fanid IS NULL

	SELECT c.RetailerID, SUM(ct.Amount) AS Spend
	FROM Relational.ConsumerTransaction ct
	INNER JOIN #Combos c ON ct.ConsumerCombinationID = c.ConsumerCombinationID
	INNER JOIN #CINs CIN ON ct.CINID = CIN.CINID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY c.RetailerID

END