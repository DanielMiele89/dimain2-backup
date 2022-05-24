
CREATE PROCEDURE [Staging].[SSRS_R0212_MIDValidation_BrandingReview]
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1.	Declare Variables
*******************************************************************************************************************************************/

	DECLARE @ValidationID INT
		,	@BrandID INT
		,	@BrandName VARCHAR(100)
		,	@LastYear DATE = DATEADD(YEAR, -1, GETDATE())

	SELECT	@ValidationID = MAX(COALESCE(ValidationID, 0))
	FROM (	SELECT MAX(ValidationID) AS ValidationID
			FROM [Staging].[MIDValidation_MIDs]
			UNION ALL
			SELECT MAX(ValidationID) AS ValidationID
			FROM [Staging].[MIDValidation_Details]) mv

	SELECT	@BrandID = MIN(BrandID)
	FROM [Staging].[MIDValidation_Details]
	WHERE ValidationID = @ValidationID

	SELECT	@BrandName = '%' + BrandName + '%'
	FROM [Relational].[Brand]
	WHERE BrandID = @BrandID
	
		
/*******************************************************************************************************************************************
	2.	Fetch wildcard lookups for the Brand
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#BrandMatch') IS NOT NULL DROP TABLE #BrandMatch
	SELECT	bm.Narrative
	INTO #BrandMatch
	FROM [Staging].[BrandMatch] bm
	WHERE bm.BrandID = @BrandID

	CREATE CLUSTERED INDEX CIX_Narrative ON #BrandMatch (Narrative)
	
		
/*******************************************************************************************************************************************
	3.	Fetch CCs that are potentially not correctly branded
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
	SELECT	cc.ConsumerCombinationID
	INTO #ConsumerCombination
	FROM [Relational].[ConsumerCombination] cc
	WHERE cc.BrandID != @BrandID
	AND cc.Narrative LIKE @BrandName
	
	UNION ALL

	SELECT	cc.ConsumerCombinationID
	FROM [Relational].[ConsumerCombination] cc
	WHERE cc.BrandID != @BrandID
	AND EXISTS (	SELECT 1
					FROM #BrandMatch bm
					WHERE cc.Narrative LIKE bm.Narrative)
	
	UNION ALL

	SELECT	cc.ConsumerCombinationID
	FROM [Relational].[ConsumerCombination] cc
	WHERE cc.BrandID != @BrandID
	AND EXISTS (SELECT	1
				FROM [Staging].[MIDValidation_MIDs] mv
				WHERE mv.ValidationID = @ValidationID
				AND cc.MID = mv.MerchantID)

	CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerCombination (ConsumerCombinationID)

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.ConsumerCombinationID
		,	br.BrandName
		,	cc.Narrative
		,	mcc.MCCDesc
		,	cc.MID
	INTO #CC
	FROM [Relational].[ConsumerCombination] cc
	INNER JOIN [Relational].[Brand] br
		ON cc.BrandID = br.BrandID
	INNER JOIN [Relational].[MCCList] mcc
		ON cc.MCCID = mcc.MCCID
	WHERE EXISTS (	SELECT 1
					FROM #ConsumerCombination c
					WHERE cc.ConsumerCombinationID = c.ConsumerCombinationID)

	CREATE CLUSTERED INDEX CIX_CCID ON #CC (ConsumerCombinationID)

		
/*******************************************************************************************************************************************
	4.	Return spend details for MID / Narratives for MIDs that appear to belong to the retailer being reviewed
*******************************************************************************************************************************************/
		
	SELECT	cc.BrandName
		,	cc.Narrative
		,	cc.MCCDesc
		,	cc.MID
		,	SUM(ct.Amount) AS SpendInLastYear
		,	MAX(ct.TranDate) AS LastTransaction
	FROM #CC cc
	INNER JOIN [Relational].[ConsumerTransaction_MyRewards] ct
		ON ct.TranDate > @LastYear
		AND cc.ConsumerCombinationID = ct.ConsumerCombinationID
	GROUP BY	cc.BrandName
			,	cc.Narrative
			,	cc.MCCDesc
			,	cc.MID
	ORDER BY	cc.MCCDesc
			,	cc.Narrative
			,	cc.BrandName
			,	cc.MID

END


