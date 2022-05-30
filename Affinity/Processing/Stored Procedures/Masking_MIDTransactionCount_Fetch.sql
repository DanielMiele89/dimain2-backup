
/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 23/09/2020
-- Description:	Returns non-branded MID tranasction counts from all the transaction
				tables that are used for the transaction files

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[Masking_MIDTransactionCount_Fetch](
	@DateType VARCHAR(10) --  The string to represent the type of date range that was used for the fetch
  , @StartDate DATE -- The start date of the range 
  , @EndDate DATE -- The end date of the range
)
AS
BEGIN

	DECLARE @RowCount INT -- Logging row count

	----------------------------------------------------------------------
	-- Load ConsumerTrans/Holding
	----------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#TranCount') IS NOT NULL
		DROP TABLE #TranCount

	SELECT
		cc.MID
	  , cc.isGB
	  , COUNT(1) AS TranCount
	INTO #TranCount
	FROM Warehouse.Relational.ConsumerTransaction ct
	JOIN Processing.Masking_ConsumerCombinations cc
		ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	GROUP BY cc.MID
		   , cc.isGB


	INSERT INTO #TranCount
	 SELECT
		 cc.MID
	   , cc.isGB
	   , COUNT(1) AS TranCount
	 FROM Warehouse.Relational.ConsumerTransactionHolding ct
	 JOIN Processing.Masking_ConsumerCombinations cc
		 ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	 WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	 GROUP BY cc.MID
			, cc.isGB

	----------------------------------------------------------------------
	-- Load ConsumerTrans_Credit/Holding
	----------------------------------------------------------------------
	INSERT INTO #TranCount

	 SELECT
		 cc.MID
	   , cc.isGB
	   , COUNT(1) AS TranCount
	 FROM Warehouse.Relational.ConsumerTransaction_CreditCard ct
	 JOIN Processing.Masking_ConsumerCombinations cc
		 ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	 WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	 GROUP BY cc.MID
			, cc.isGB


	INSERT INTO #TranCount

	 SELECT
		 cc.MID
	   , cc.isGB
	   , COUNT(1) AS TranCount
	 FROM Warehouse.Relational.ConsumerTransaction_CreditCardHolding ct
	 JOIN Processing.Masking_ConsumerCombinations cc
		 ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
	 WHERE ct.TranDate BETWEEN @StartDate AND @EndDate
	 GROUP BY cc.MID
			, cc.isGB

	----------------------------------------------------------------------
	-- Load nFI Trans
	----------------------------------------------------------------------
	INSERT INTO #TranCount

	 SELECT
		 cc.MID
	   , cc.isGB
	   , COUNT(1) AS TranCount
	 FROM SLC_REPL..Match ct
	 INNER JOIN SLC_REPL..RetailOutlet RO
		 ON RO.ID = ct.RetailOutletID
	 INNER JOIN Warehouse.Relational.Partner pa
		 ON pa.PartnerID = RO.PartnerID
	 INNER JOIN Processing.Masking_ConsumerCombinations cc
		 ON cc.MID = ct.MerchantID
			 AND cc.BrandID = pa.BrandID
			 AND cc.rw = 1
	 WHERE ct.TransactionDate BETWEEN @StartDate AND @EndDate
	 GROUP BY cc.MID
			, cc.isGB

	CREATE CLUSTERED INDEX cix_stuff ON #TranCount (MID, isGB)
	----------------------------------------------------------------------
	-- Aggregate and load
	----------------------------------------------------------------------

	INSERT INTO Processing.Masking_MIDTransactionCount
	(
		DateType
	  , DateStart
	  , DateEnd
	  , MID
	  , TranCount
	  , isGB
	)
	 SELECT
		 @DateType		AS DateType
	   , @StartDate		AS StartDate
	   , @EndDate		AS EndDate
	   , x.MID
	   , SUM(TranCount) AS TranCount
	   , x.isGB
	 FROM #TranCount x
	 GROUP BY x.MID
			, x.isGB

	SELECT @RowCount += @@rowcount

	RETURN @RowCount

END
