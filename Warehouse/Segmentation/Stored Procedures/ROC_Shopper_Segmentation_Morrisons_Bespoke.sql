
/******************************************************************************
Author: Jason Shipp
Created: 19/04/2018
Purpose:
	- Segments control group members into ALS groups and sub-groups, using bespoke rules defined by Morrisons
	- Segments: Acquire, Lapsed, Shopper Risk Of Lapsing and Shopper Grow

------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE Segmentation.ROC_Shopper_Segmentation_Morrisons_Bespoke
	(@PartnerNo INT = 4263
	, @EnDate DATE
	, @TName VARCHAR(200)
	)

WITH EXECUTE AS OWNER

AS
BEGIN

	SET NOCOUNT ON;
	
	---- For testing
	--DECLARE @PartnerNo INT = 4263 -- Morrisons
	--DECLARE @EnDate DATE = '2018-03-29'
	--DECLARE @TName VARCHAR(200) = 'Sandbox.jason.Control426320180329'

	DECLARE
		@PartnerID INT
		, @BrandID INT
		, @EndDate DATE = @EnDate;

	SET @PartnerID = @PartnerNo;
	
	/***********************************************************************************************
	Load out of programme base control customers
	***********************************************************************************************/
	
	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;

	SELECT
		cg.FanID
		, cg.CINID
		, ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
	INTO #Customers
	FROM Segmentation.ROC_Shopper_Segment_CtrlGroup AS cg
	LEFT JOIN Relational.Customer AS c
		ON cg.FanID = c.FanID
	WHERE 
		c.FanID is null -- Out of programme
		and cg.StartDate <= @EndDate
		and (cg.EndDate is null or cg.EndDate > @EndDate);
	
	CREATE CLUSTERED INDEX i_Customer_CINID ON #Customers (CINID);
	CREATE NONCLUSTERED INDEX i_Customer_FanID ON #Customers (FanID);
	CREATE NONCLUSTERED INDEX i_Customer_RowNo ON #Customers (RowNo);

	/***********************************************************************************************
	Load Consumer Combinations
	***********************************************************************************************/

	SET @BrandID = (SELECT DISTINCT BrandID FROM Warehouse.Relational.[Partner] WHERE PartnerID = @PartnerID);

	IF OBJECT_ID ('tempdb..#CC') IS NOT NULL DROP TABLE #CC;

	SELECT
		ConsumerCombinationID
		, BrandID
		, MID
		, Narrative
		, LocationCountry
	INTO #CC
	FROM Relational.ConsumerCombination AS cc
	WHERE
		BrandID = @BrandID;

	CREATE CLUSTERED INDEX i_CC_CCID ON #CC (ConsumerCombinationID);

	/***********************************************************************************************
	Load base control customer spend history
	***********************************************************************************************/
	
	-- Define segment lengths (Control members last spent between the given dates)
	
	DECLARE @Acquire INT = 6
	DECLARE @Lapsed INT = 3
	DECLARE @Shopper INT = 2

	DECLARE @AcquireDate DATE = DATEADD(MONTH,-@Acquire,DATEADD(DAY,-1,@EnDate))
	DECLARE @LapsedDate DATE = DATEADD(MONTH,-@Lapsed,DATEADD(DAY,-1,@EnDate))
	DECLARE @ShopperDate DATE = DATEADD(MONTH,-@Shopper,DATEADD(DAY,-1,@EnDate))
	DECLARE @MaxDate DATE = DATEADD(DAY,-1,@EnDate)

	-- Load debit transactions (including ConsumerTransactionHolding)

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans;

	SELECT
		t.CINID
		, t.FanID
		, t.Amount
		, t.TranDate
	INTO #Trans
	FROM (
		SELECT
			ct.CINID
			, pop.FanID
			, ct.Amount
			,ct.TranDate
		FROM #Customers pop
		LEFT JOIN (
				SELECT 
				ct.CINID
				, ct.Amount
				, ct.TranDate			
				FROM Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
				INNER JOIN #CC cc ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
			) ct
			ON pop.CINID = ct.CINID
			AND ct.TranDate BETWEEN @AcquireDate AND @MaxDate
			AND ct.Amount >0
		UNION
		SELECT
			cth.CINID
			, pop.FanID
			, cth.Amount
			, cth.TranDate
		FROM #Customers pop
		LEFT JOIN (
				SELECT 
				cth.CINID
				, cth.Amount
				, cth.TranDate			
				FROM Warehouse.Relational.ConsumerTransactionHolding cth WITH (NOLOCK)
				INNER JOIN #CC cc ON cth.ConsumerCombinationID = cc.ConsumerCombinationID
			) cth
			ON pop.CINID = cth.CINID
			AND cth.TranDate BETWEEN @AcquireDate AND @MaxDate
			AND cth.Amount >0
		) t;

	CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #Trans (TranDate);
	CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #Trans (TranDate) INCLUDE (CINID);

	/***********************************************************************************************
	Assign customer propensity segments
	***********************************************************************************************/

	IF OBJECT_ID('tempdb..#Segment') IS NOT NULL DROP TABLE #Segment;

	SELECT
		a.CINID
		, a.FanID
		, a.Sales
		, CASE
			WHEN @AcquireDate <= LatestTrans AND LatestTrans < @LapsedDate THEN 'Lapsed' -- Last spend 3-6 months before offer start
			WHEN @LapsedDate <= LatestTrans AND LatestTrans <= @MaxDate THEN 'Shopper' -- Last spend 0-3 months before offer start
			ELSE 'Acquire' -- Last spend over 6 months before offer start
		END AS Segment
		, CASE
			WHEN @LapsedDate <= LatestTrans AND LatestTrans < @ShopperDate THEN 'Risk of Lapsing' -- Last spend 2-3 months before offer start
			WHEN @ShopperDate <= LatestTrans AND LatestTrans <= @MaxDate THEN 'Grow' -- Last spend 0-2 months before offer start 
			ELSE NULL
		END AS ShopperSub
	INTO #Segment
	FROM (
		SELECT
		t.CINID
		, t.FanID
		, SUM(t.Amount) AS Sales
		, MAX(t.TranDate) AS LatestTrans
		FROM #Trans t
		GROUP BY t.CINID, t.FanID
	) a;

	CREATE CLUSTERED INDEX cix_CINID ON #Segment (CINID);

	IF OBJECT_ID('tempdb..#NTILE') IS NOT NULL DROP TABLE #NTILE;

	SELECT	
		s.FanID
		, s.CINID
		, s.Sales AS RankingFeature
		, s.Segment
		, s.ShopperSub
		, NTILE(4) OVER (PARTITION BY s.Segment ORDER BY s.Sales DESC) AS PropensityScore
	INTO #NTILE
	FROM #Segment s;

	/***********************************************************************************************
	Load retailer share of wallet per customer
	***********************************************************************************************/

	DECLARE @SectorList VARCHAR(500) = '5,21,92,254,292,379,425,485'

	-- Load brand sectors

	IF OBJECT_ID('tempdb..#SectorBrand') IS NOT NULL DROP TABLE #SectorBrand;

	SELECT
		BrandID
		, BrandName
		, ROW_NUMBER() OVER (ORDER BY BrandID) AS RowNo
	INTO #SectorBrand
	FROM Warehouse.Relational.Brand
	WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @SectorList + ',') > 0;

	CREATE CLUSTERED INDEX cix_BrandID ON #SectorBrand (BrandID);

	-- Load ConsumerCombinationIDs
	
	IF OBJECT_ID('tempdb..#SectorCC') IS NOT NULL DROP TABLE #SectorCC;

	SELECT
	  cc.BrandID
	  , cc.ConsumerCombinationID
	INTO #SectorCC
	FROM Warehouse.Relational.ConsumerCombination cc
	INNER JOIN #SectorBrand br
		ON cc.BrandID = br.BrandID;

	CREATE NONCLUSTERED INDEX nix_Combo ON #SectorCC (ConsumerCombinationID) INCLUDE (BrandID);

	-- Load brand transactions
	
	IF OBJECT_ID('tempdb..#SectorTrans') IS NOT NULL DROP TABLE #SectorTrans;

	SELECT	
		t.BrandID
		, t.CINID
		, t.Amount
		, t.TranDate
		, t.IsOnline
	INTO #SectorTrans
	FROM (
		SELECT
			cc.BrandID
			, ct.CINID
			, ct.Amount
			, ct.TranDate
			, ct.IsOnline
		FROM Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
		INNER JOIN #SectorCC cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		INNER JOIN	#Customers pop
			ON ct.CINID = pop.CINID
		WHERE
			@AcquireDate <= ct.TranDate
			AND	ct.TranDate  <= @MaxDate
			AND 0 < ct.Amount
		UNION
		SELECT
			cc.BrandID
			, cth.CINID
			, cth.Amount
			, cth.TranDate
			, cth.IsOnline
		FROM Warehouse.Relational.ConsumerTransactionHolding cth WITH (NOLOCK)
		INNER JOIN #SectorCC cc
			ON cth.ConsumerCombinationID = cc.ConsumerCombinationID
		INNER JOIN #Customers pop
			ON cth.CINID = pop.CINID
		WHERE
			@AcquireDate <= cth.TranDate
			AND	cth.TranDate  <= @MaxDate
			AND 0 < cth.Amount
		) t

	CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #SectorTrans (TranDate);
	CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #SectorTrans (TranDate) INCLUDE (CINID);

	-- Load customer sector transaction summary

	IF OBJECT_ID('tempdb..#SectorSummary') IS NOT NULL DROP TABLE #SectorSummary;
	
	SELECT
		CINID
		, SUM(CASE WHEN BrandID = @BrandID THEN Amount ELSE 0 END) AS BrandSales
		, SUM(Amount) AS SectorSales
		, SUM(CASE WHEN IsOnline = 1 THEN Amount ELSE 0 END) AS OnlineSales
	INTO #SectorSummary
	FROM #SectorTrans
	GROUP BY
		CINID;

	CREATE CLUSTERED INDEX cix_CINID ON #SectorSummary (CINID);
		
	-- Load retailer share of wallet per customer

	IF OBJECT_ID('tempdb..#SectorSummary2') IS NOT NULL DROP TABLE #SectorSummary2;

	SELECT
		a.CINID
		, a.BrandSales
		, a.SectorSales
		, a.OnlineSales
		, COALESCE(1.0*BrandSales/NULLIF(SectorSales,0),0) AS BrandSoW
	INTO #SectorSummary2
	FROM #SectorSummary a;

	CREATE CLUSTERED INDEX cix_CINID ON #SectorSummary2 (CINID);
	
	/***********************************************************************************************
	Load control member segments
	***********************************************************************************************/

	-- Load base data

	IF OBJECT_ID('tempdb..#PreSelection') IS NOT NULL DROP TABLE #PreSelection;
	
	SELECT
		a.FanID
		, a.CINID
		, a.RankingFeature
		, a.Segment
		, a.ShopperSub
		, a.PropensityScore
		, ss.BrandSoW
		, ss.OnlineSales
	INTO #PreSelection
	FROM #NTILE a
	LEFT JOIN #SectorSummary2 ss
		ON a.CINID = ss.CINID;

	CREATE NONCLUSTERED INDEX nix_ComboID ON #PreSelection (Segment) INCLUDE (CINID);

	-- Load segment assignment

	IF OBJECT_ID('tempdb..#Selection') IS NOT NULL DROP TABLE #Selection;
		
	SELECT *
	INTO #Selection
	FROM (
			SELECT	
				2 AS SegmentID -- Assigned to Acquire
				, 'Acquire' AS Selection
				, FanID
				, CINID
				, Segment
				, PropensityScore
			FROM #PreSelection
			WHERE
				PropensityScore IN (1,2,3,4)
				AND	Segment IN ('Acquire')			
			
			UNION
			
			SELECT
				3 AS SegmentID -- Assigned to Winback
				, 'Lapsed' AS Selection
				, FanID
				, CINID
				, Segment
				, PropensityScore
			FROM #PreSelection
			WHERE
				PropensityScore IN (1,2,3)
				AND	Segment IN ('Lapsed')
			
			UNION
			
			SELECT 
				6 AS SegmentID -- Assigned to Retain
				, 'Shopper Risk Of Lapsing' AS Selection
				, FanID
				, CINID
				, Segment
				, PropensityScore
			FROM #PreSelection
			WHERE 
				PropensityScore IN (1,2,3)
				AND	Segment IN ('Shopper')
				AND	ShopperSub IN ('Risk of Lapsing')
				AND BrandSoW < 0.25
			
			UNION
			
			SELECT
				5 AS SegmentID -- Assigned to Grow
				, 'Shopper Grow' AS Selection
				, FanID
				, CINID
				, Segment
				, PropensityScore
			FROM #PreSelection
			WHERE
				PropensityScore IN (1,2,3)
				AND	Segment IN ('Shopper')
				AND	ShopperSub IN ('Grow')
				AND BrandSoW < 0.25
			) a;

	/***********************************************************************************************
	Load control members, along with segment types
	***********************************************************************************************/

	DECLARE @Qry NVARCHAR(MAX);

	Set @Qry =
	'If object_id('''+@TName+''') is not null drop table '+@TName+';
	'+'Select	
		FanID
		, '+Cast(@PartnerID as Varchar(5))+' as PartnerID
		, SegmentID
	Into '+@TName+'
	From #Selection';

	EXEC sp_executeSQL @Qry;

END