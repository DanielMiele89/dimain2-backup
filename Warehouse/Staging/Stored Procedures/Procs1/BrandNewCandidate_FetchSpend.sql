
CREATE PROCEDURE [Staging].[BrandNewCandidate_FetchSpend] @BrandID INT
AS
	BEGIN

	/*******************************************************************************************************************************************
		1.	Declare variables
	*******************************************************************************************************************************************/

		--DECLARE @BrandID INT = 129	--	For testing

		DECLARE @EndDate DATE = EOMONTH(GETDATE(), -1)
		DECLARE @StartDateYear DATE = DATEADD(year, -1, @EndDate)
		DECLARE @StartDatePrevious2Years DATE = DATEADD(year, -2, @EndDate)

		ALTER INDEX CIX_CCID ON [Staging].[BrandNewCandidate_POS] REBUILD
		ALTER INDEX CIX_CCID ON [Staging].[BrandNewCandidate_DD] REBUILD

	/*******************************************************************************************************************************************
		2.	Fetch Combinations
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ConsumerCombination') IS NOT NULL DROP TABLE #ConsumerCombination
		SELECT	cc.ConsumerCombinationID
			,	CASE
					WHEN cc.BrandID = @BrandID THEN 1
					ELSE 0
				END AS AlreadyBranded
		INTO #ConsumerCombination
		FROM [Relational].[ConsumerCombination] cc
		WHERE BrandID = @BrandID
		OR EXISTS (	SELECT 1 
					FROM [Staging].[BrandNewCandidate_POS] bnc
					WHERE cc.ConsumerCombinationID = bnc.ConsumerCombinationID)

		CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerCombination (ConsumerCombinationID)

		IF OBJECT_ID('tempdb..#ConsumerCombination_DD') IS NOT NULL DROP TABLE #ConsumerCombination_DD
		SELECT	cc.ConsumerCombinationID_DD
			,	CASE
					WHEN cc.BrandID = @BrandID THEN 1
					ELSE 0
				END AS AlreadyBranded
		INTO #ConsumerCombination_DD
		FROM [Relational].[ConsumerCombination_DD] cc
		WHERE BrandID = @BrandID
		OR EXISTS (	SELECT 1 
					FROM [Staging].[BrandNewCandidate_DD] bnc
					WHERE cc.ConsumerCombinationID_DD = bnc.ConsumerCombinationID_DD)

		CREATE CLUSTERED INDEX CIX_CCID ON #ConsumerCombination_DD (ConsumerCombinationID_DD)


	/*******************************************************************************************************************************************
		2.	Fetch annual spend by month
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#SpendByMonth_Debit') IS NOT NULL DROP TABLE #SpendByMonth_Debit
		SELECT	'POS - Debit' AS Transactiontype
			,	YEAR(TranDate) AS TranYear
			,	MONTH(TranDate) AS TranMonth
			,	COALESCE(SUM(Amount * AlreadyBranded), 0) AS OriginalSpend
			,	COALESCE(SUM(Amount), 0) AS UpdatedSpend
			,	COUNT(DISTINCT ct.ConsumerCombinationID) AS Combinations
		INTO #SpendByMonth_Debit
		FROM [Relational].[ConsumerTransaction] ct WITH (NOLOCK)
		INNER JOIN #ConsumerCombination cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDatePrevious2Years AND @EndDate
		GROUP BY YEAR(TranDate)
			   , MONTH(TranDate)
		   
		IF OBJECT_ID('tempdb..#SpendByMonth_Credit') IS NOT NULL DROP TABLE #SpendByMonth_Credit
		SELECT	'POS - Credit' AS Transactiontype
			,	YEAR(TranDate) AS TranYear
			,	MONTH(TranDate) AS TranMonth
			,	COALESCE(SUM(Amount * AlreadyBranded), 0) AS OriginalSpend
			,	COALESCE(SUM(Amount), 0) AS UpdatedSpend
			,	COUNT(DISTINCT ct.ConsumerCombinationID) AS Combinations
		INTO #SpendByMonth_Credit
		FROM [Relational].[ConsumerTransaction_CreditCard] ct WITH (NOLOCK)
		INNER JOIN #ConsumerCombination cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		WHERE ct.TranDate BETWEEN @StartDatePrevious2Years AND @EndDate
		GROUP BY YEAR(TranDate)
			   , MONTH(TranDate)
		   
		IF OBJECT_ID('tempdb..#SpendByMonth_DirectDebit') IS NOT NULL DROP TABLE #SpendByMonth_DirectDebit
		SELECT	'Direct Debit' AS TransactionType
			,	YEAR(TranDate) AS TranYear
			,	MONTH(TranDate) AS TranMonth
			,	COALESCE(SUM(Amount * AlreadyBranded), 0) AS OriginalSpend
			,	COALESCE(SUM(Amount), 0) AS UpdatedSpend
			,	COUNT(DISTINCT ct.ConsumerCombinationID_DD) AS Combinations
		INTO #SpendByMonth_DirectDebit
		FROM [Relational].[ConsumerTransaction_DD] ct WITH (NOLOCK)
		INNER JOIN #ConsumerCombination_DD bnc
			ON ct.ConsumerCombinationID_DD = bnc.ConsumerCombinationID_DD
		WHERE ct.TranDate BETWEEN @StartDatePrevious2Years AND @EndDate
		GROUP BY YEAR(TranDate)
			   , MONTH(TranDate)
		   
		IF OBJECT_ID('tempdb..#SpendByMonth_Months') IS NOT NULL DROP TABLE #SpendByMonth_Months
		SELECT	DISTINCT
				TranYear
			,	TranMonth
		INTO #SpendByMonth_Months
		FROM #SpendByMonth_Debit
		UNION
		SELECT	DISTINCT
				TranYear
			,	TranMonth
		FROM #SpendByMonth_Credit
		UNION
		SELECT	DISTINCT
				TranYear
			,	TranMonth
		FROM #SpendByMonth_DirectDebit


	/*******************************************************************************************************************************************
		3.	Output annual spend
	*******************************************************************************************************************************************/
	
		SELECT	'POS - Debit' AS TransactionType
			,	COALESCE(SUM(sbm.OriginalSpend), 0) AS OriginalSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) AS UpdatedSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) - COALESCE(SUM(sbm.OriginalSpend), 0) AS ChangeInSpend_DD
		FROM #SpendByMonth_Debit sbm
		WHERE @StartDateYear <= DATEFROMPARTS(sbm.TranYear, sbm.TranMonth, 1)
		UNION ALL
		SELECT	'POS - Credit' AS TransactionType
			,	COALESCE(SUM(sbm.OriginalSpend), 0) AS OriginalSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) AS UpdatedSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) - COALESCE(SUM(sbm.OriginalSpend), 0) AS ChangeInSpend_DD
		FROM #SpendByMonth_Credit sbm
		WHERE @StartDateYear <= DATEFROMPARTS(sbm.TranYear, sbm.TranMonth, 1)
		UNION ALL
		SELECT	'Direct Debit' AS TransactionType
			,	COALESCE(SUM(sbm.OriginalSpend), 0) AS OriginalSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) AS UpdatedSpend
			,	COALESCE(SUM(sbm.UpdatedSpend), 0) - COALESCE(SUM(sbm.OriginalSpend), 0) AS ChangeInSpend_DD
		FROM #SpendByMonth_DirectDebit sbm
		WHERE @StartDateYear <= DATEFROMPARTS(sbm.TranYear, sbm.TranMonth, 1)
		ORDER BY TransactionType

	/*******************************************************************************************************************************************
		4.	Output spend by month
	*******************************************************************************************************************************************/

		SELECT	m.TranYear
			,	m.TranMonth
			,	COALESCE(d.UpdatedSpend, 0) + COALESCE(c.UpdatedSpend, 0) - COALESCE(d.OriginalSpend, 0) - COALESCE(c.OriginalSpend, 0) AS ChangeInSpend_POS
			,	COALESCE(dd.UpdatedSpend, 0) - COALESCE(dd.OriginalSpend, 0) AS ChangeInSpend_DD

			,	COALESCE(d.OriginalSpend, 0) + COALESCE(c.OriginalSpend, 0) AS OriginalSpend_POS
			,	COALESCE(d.UpdatedSpend, 0) + COALESCE(c.UpdatedSpend, 0) AS UpdatedSpend_POS

			,	COALESCE(dd.OriginalSpend, 0) AS OriginalSpend_DD
			,	COALESCE(dd.UpdatedSpend, 0) AS UpdatedSpend_DD
		FROM #SpendByMonth_Months m
		LEFT JOIN #SpendByMonth_Debit d
			ON m.TranYear = d.TranYear
			AND m.TranMonth = d.TranMonth
		LEFT JOIN #SpendByMonth_Credit c
			ON m.TranYear = c.TranYear
			AND m.TranMonth = c.TranMonth
		LEFT JOIN #SpendByMonth_DirectDebit dd
			ON m.TranYear = dd.TranYear
			AND m.TranMonth = dd.TranMonth
		ORDER BY	m.TranYear
				,	m.TranMonth

END