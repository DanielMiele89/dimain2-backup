/**************************************************************************
-- Author: Jason Shipp
-- Create date: 25/01/2018
-- Description:	
	- Fetch incentivised and non-incentivised ConsumerTransaction data, and join to publisher cardholder base
	- Aggregate results by retailer and month, and use results to refresh APW.RetailerPotentialValue_Monthly_BaseSpend table

-- Modification History:

Jason Shipp 29/05/2018
	- Changed logic for default start and end dates to point to the start and end of the previous calendar year
	- Changed refresh of APW.RetailerPotentialValue_Monthly_BaseSpend to an insertion of new rows
	- Added ability to add bespoke PartnerIDs to analysis
***************************************************************************/

CREATE PROCEDURE APW.RetailerPotentialValue_Monthly_ConsumerTrans_Load

AS 
BEGIN

	SET NOCOUNT ON;

	/**************************************************************************
	Declare Variables
	***************************************************************************/

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @AnalysisStartDate DATE = ( -- Start date of previous calendar year
		SELECT DATEADD(year,-1
			, DATEADD(year 
				,DATEDIFF(year,0,@Today)
			,0)
		)
	);
	DECLARE @AnalysisEndDate DATE = ( -- End date of previous calendar year
		SELECT DATEADD(day, -1
			, DATEADD(year, 1, @AnalysisStartDate))
	);

	/******************************************************************************
	Load partner alternates
	******************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerAlternate') IS NOT NULL DROP TABLE #PartnerAlternate;

	SELECT DISTINCT * 
	INTO #PartnerAlternate
	FROM 
		(SELECT 
		PartnerID
		, AlternatePartnerID
		FROM Warehouse.APW.PartnerAlternate

		UNION ALL  

		SELECT 
		PartnerID
		, AlternatePartnerID
		FROM nFI.APW.PartnerAlternate
		) x;

	/**************************************************************************
	Load table of bespoke PartnerIDs to include in analysis (these partners do not need to have any incentivised spend)
	***************************************************************************/

	IF OBJECT_ID('tempdb..#ExtraPartnerIDs') IS NOT NULL DROP TABLE #ExtraPartnerIDs;

	CREATE TABLE #ExtraPartnerIDs (
		PartnerID int NOT NULL
	)

	INSERT INTO #ExtraPartnerIDs (
		PartnerID
	)
	VALUES -- Change values as required- list will come from CS (via Gabor)
		(4715); 
	
	-- Load associated BrandIDs

	IF OBJECT_ID('tempdb..#ExtraPartnerBrands') IS NOT NULL DROP TABLE #ExtraPartnerBrands;

	SELECT
		COALESCE(pa.AlternatePartnerID, e.PartnerID) AS RetailerID 
		, b.BrandID
	INTO #ExtraPartnerBrands
	FROM #ExtraPartnerIDs e
	INNER JOIN Warehouse.Relational.[Partner] p
		ON e.PartnerID = p.PartnerID
	LEFT JOIN #PartnerAlternate pa
		ON p.PartnerID = pa.PartnerID
	INNER JOIN Warehouse.Relational.Brand b
		ON p.BrandID = b.BrandID;

	/**************************************************************************
	Create calendar table of month dates for the previous calendar year
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar;

	CREATE TABLE #Calendar
		(StartDate DATE NOT NULL
		, EndDate DATE NOT NULL
		, IsMonthly BIT
		, RowNumber INT IDENTITY (1,1)
		);

	WITH cte AS
		(SELECT @AnalysisStartDate AS StartDate -- Anchor member
		UNION ALL
		SELECT DATEADD(DAY, 1, EOMONTH(StartDate)) -- Month start date: recursive member
		FROM   cte
		WHERE StartDate <= DATEADD(MONTH, -1, @AnalysisEndDate) -- Terminator: month before most recent month-end
		)
	INSERT INTO #Calendar
		(StartDate
		, EndDate
		, IsMonthly
		)
	SELECT
		cte.StartDate
		, EOMONTH(cte.StartDate) AS EndDate
		, 1 AS IsMonthly
	FROM cte

	OPTION (MAXRECURSION 1000);

	CREATE CLUSTERED INDEX cix_calendarYTD ON #Calendar (StartDate, EndDate);

	/**************************************************************************
	Fetch Big Payment spend data associated with RBS cardholder base
	***************************************************************************/

	-- Fetch retailers to be analysed

	IF OBJECT_ID('tempdb..#ConsumerCombos') IS NOT NULL DROP TABLE #ConsumerCombos;

	SELECT DISTINCT
		cc.ConsumerCombinationID
		, b.RetailerID
	INTO #ConsumerCombos
	FROM (
		SELECT BrandID, RetailerID FROM APW.RetailerPotentialValue_Brand
		UNION
		SELECT BrandID, RetailerID FROM #ExtraPartnerBrands
	) b
	INNER JOIN Relational.ConsumerCombination cc
		ON b.BrandID = cc.BrandID;

	CREATE CLUSTERED INDEX cix_Combos ON #ConsumerCombos (RetailerID);

	-- Iterate over months in #Calendar table

	DECLARE @maxrow INT = (SELECT COUNT(1) FROM #Calendar)
	DECLARE @rowNum INT = 0
		DECLARE @StMonth DATE
	DECLARE @EOMonth DATE

	WHILE @rowNum < @maxRow  -- Iterate over calendar rows

	BEGIN

		SET @rowNum = @rowNum + 1

		SET @StMonth = (SELECT StartDate FROM #Calendar WHERE RowNumber = @rowNum)
		SET @EOMonth = (SELECT EndDate FROM #Calendar WHERE RowNumber = @rowNum)
		
		-- Fetch the unique RBS cardholders active at the end of the given month, from the publisher base

		IF OBJECT_ID('tempdb..#CINs') IS NOT NULL DROP TABLE #CINs;
			
		SELECT DISTINCT
			cl.CINID
		INTO #CINs
		FROM Relational.CINList cl
		INNER JOIN Relational.Customer c
			ON cl.CIN = c.SourceUID
		INNER JOIN APW.RetailerPotentialValue_Monthly_Cardholder ch
			ON c.FanID = ch.FanID
		LEFT JOIN MI.CINDuplicate d
			ON c.fanID = d.fanid
		WHERE
			d.fanid IS NULL
			AND ch.PublisherID = 132
			AND ch.ActiveFromDate <= @EOMonth
			AND (ch.DeactivationDate IS NULL OR ch.DeactivationDate > @EOMonth)
			AND (ch.RemovalDate IS NULL OR ch.RemovalDate > @EOMonth);

		ALTER TABLE #CINs ADD CONSTRAINT PK_CIX_CINs PRIMARY KEY CLUSTERED (CINID ASC);
		
		-- Fetch and aggregate the transactions for the given customers for the given month, and store new results
			
		INSERT INTO APW.RetailerPotentialValue_Monthly_BaseSpend (
			 StartDate
			, EndDate
			, RetailerID
			, Spend)

		SELECT
			@StMonth AS StartDate
			, @EOMonth AS EndDate
			, cc.RetailerID
			, SUM(ct.Amount) AS Spend
		FROM Relational.ConsumerTransaction ct WITH(NOLOCK)
		INNER JOIN #ConsumerCombos cc
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		INNER JOIN #CINs c
		ON ct.CINID = c.CINID
		WHERE
			ct.TranDate BETWEEN @StMonth AND @EOMonth
			AND NOT EXISTS (
				SELECT NULL FROM Warehouse.APW.RetailerPotentialValue_Monthly_BaseSpend x
				WHERE 
					@StMonth = x.StartDate
					AND @EOMonth = x.EndDate
					AND cc.RetailerID = x.RetailerID
			)					
		GROUP BY cc.RetailerID;

		/**************************************************************************
		-- Create table for storing results

		CREATE TABLE Warehouse.APW.RetailerPotentialValue_Monthly_BaseSpend (
			ID INT IDENTITY (1,1)
			, StartDate DATE
			, EndDate DATE
			, RetailerID INT
			, Spend MONEY
		);

		ALTER TABLE APW.RetailerPotentialValue_Monthly_BaseSpend 
			ADD CONSTRAINT PK_RetailerPotentialValue_Monthly_BaseSpend PRIMARY KEY (ID);
		***************************************************************************/
	END

END