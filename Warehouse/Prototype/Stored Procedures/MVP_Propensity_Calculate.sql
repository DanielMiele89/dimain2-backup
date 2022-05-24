/* =============================================
-- Author:		<Shaun Hide>
-- Create date: <9th July 2018>
-- Description:	{

	Takes @BrandList and does the following
		1) Find a random 1.5m control group from MVP_ControlAdjustedSCD
		2) Find a random 1.5m exposed group from MVP_Engagement
		3) Profile each of the above groups - Segment, Spend, Trans, Spenders
		4) Profile the spend of the above groups - for Spend Stretch

				}
-- =============================================
*/
CREATE PROCEDURE Prototype.MVP_Propensity_Calculate
	@BrandList VARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @time DATETIME,
			@msg VARCHAR(100)


	EXEC	Warehouse.Prototype.oo_TimerMessage ' Propensity Table Script Started ', @time OUTPUT

	-- Find Brands

	IF OBJECT_ID('tempdb..#BrandList') IS NOT NULL DROP TABLE #BrandList
	CREATE TABLE #BrandList
		(
			BrandID INT,
			BrandName VARCHAR(50),
			AcquireLength INT,
			LapsedLength INT,
			RowNo INT
		)

	IF @BrandList IS NULL	-- Fortnightly Update
		BEGIN
			TRUNCATE TABLE Warehouse.Prototype.MVP_SpendStretchPropensityRank
			TRUNCATE TABLE Warehouse.Prototype.MVP_SpendStretchTotal
			TRUNCATE TABLE Warehouse.Prototype.MVP_NaturalSalesByCycle

			INSERT INTO #BrandList
				SELECT	BrandID,
						BrandName,
						AcquireLength,
						LapsedLength,
						ROW_NUMBER() OVER (ORDER BY BrandID DESC) AS RowNo
				FROM	Warehouse.Prototype.MVP_BrandList
				WHERE	EndDate IS NULL
		END
	ELSE					-- Brand(s) Addition/Refresh
		BEGIN
		
			DELETE FROM Warehouse.Prototype.MVP_SpendStretchPropensityRank WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
			DELETE FROM Warehouse.Prototype.MVP_SpendStretchTotal WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
			DELETE FROM Warehouse.Prototype.MVP_NaturalSalesByCycle WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

			INSERT INTO #BrandList
				SELECT	BrandID,
						BrandName,
						AcquireLength,
						LapsedLength,
						ROW_NUMBER() OVER (ORDER BY BrandID DESC) AS RowNo
				FROM	Warehouse.Prototype.MVP_BrandList
				WHERE	EndDate IS NULL
					AND	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	CREATE CLUSTERED INDEX cix_BrandID ON #BrandList (BrandID)

	-- SELECT * FROM #BrandList
	EXEC	Warehouse.Prototype.oo_TimerMessage ' #BrandList ', @time OUTPUT

	-- Find Dates
	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	SELECT	ID,
			CycleStart,
			CycleEnd,
			DATEADD(DAY,-(DAY(CycleStart)-1), CycleStart) AS MonthDate
	INTO	#Dates
	FROM	Warehouse.Prototype.MVP_DateTable dt
	WHERE	FlaggedDate = 1
	ORDER BY CycleStart DESC

	CREATE CLUSTERED INDEX cix_CycleStart ON #Dates (CycleStart)

	-- SELECT * FROM #Dates
	EXEC	Warehouse.Prototype.oo_TimerMessage ' #Dates ', @time OUTPUT

	DECLARE @MinCycle DATE = (SELECT MIN(CycleStart) FROM #Dates)

	IF OBJECT_ID('tempdb..#BrandDates') IS NOT NULL DROP TABLE #BrandDates
	SELECT	ID,
			BrandID,
			DATEADD(MONTH,-b.AcquireLength,DATEADD(DAY,-1,CycleStart)) AS AcquireDate,
			DATEADD(MONTH,-b.LapsedLength,DATEADD(DAY,-1,CycleStart)) AS LapsedDate,
			DATEADD(DAY,-1,CycleStart) AS MaxDate,
			CycleStart,
			CycleEnd,
			MonthDate
	INTO	#BrandDates
	FROM	#Dates d
	CROSS JOIN #BrandList b

	-- INDEXING
	CREATE CLUSTERED INDEX cix_ID ON #BrandDates (ID)
	CREATE NONCLUSTERED INDEX nix_AcquireLapsed ON #BrandDates (ID) INCLUDE (AcquireDate, LapsedDate)
	CREATE NONCLUSTERED INDEX nix_LapsedShopper ON #BrandDates (ID) INCLUDE (LapsedDate, MaxDate)
	CREATE NONCLUSTERED INDEX nix_Cycles ON #BrandDates (ID) INCLUDE (CycleStart, CycleEnd)

	-- SELECT * FROM #BrandDates
	EXEC	Warehouse.Prototype.oo_TimerMessage ' #BrandDates ', @time OUTPUT

	-- Find ConsumerCombinationIDs
	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.BrandID,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc
	JOIN	#BrandList br
		ON	cc.BrandID = br.BrandID

	CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC (ConsumerCombinationID)
	CREATE NONCLUSTERED INDEX nix_ComboID ON #CC (ConsumerCombinationID) INCLUDE (BrandID)

	-- SELECT TOP 100 * FROM #CC
	EXEC	Warehouse.Prototype.oo_TimerMessage ' #CC ', @time OUTPUT

	-- Find Control Customers

	IF OBJECT_ID('tempdb..#ControlByID') IS NOT NULL DROP TABLE #ControlByID
	SELECT	d.ID,
			x.CINID
	INTO	#ControlByID
	FROM (
		   SELECT ID, DATEADD(DAY,-(DAY(CycleStart)-1), CycleStart) AS MonthDate
		   FROM Warehouse.Prototype.MVP_DateTable dt
		   WHERE FlaggedDate = 1
	) d
	CROSS APPLY (
		   SELECT TOP(1500000) CINID
		   FROM Warehouse.Prototype.MVP_ControlAdjustedSCD ca
		   WHERE ca.StartDate <= d.MonthDate AND (d.MonthDate <= ca.EndDate OR ca.EndDate IS NULL)
		   ORDER BY NEWID()
	) x

	CREATE CLUSTERED INDEX cix_CINID ON #ControlByID (CINID)
	CREATE NONCLUSTERED INDEX nix_ComboID ON #ControlByID (ID) INCLUDE (CINID)

	EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlByID ', @time OUTPUT

	IF OBJECT_ID('tempdb..#Control') IS NOT NULL DROP TABLE #Control
	SELECT	DISTINCT CINID
	INTO	#Control
	FROM	#ControlByID

	CREATE CLUSTERED INDEX cix_CINID ON #Control (CINID)

	EXEC	Warehouse.Prototype.oo_TimerMessage ' #Control ', @time OUTPUT

	/*
	-- Check
	SELECT	ID,
			COUNT(CINID) AS Population
	FROM	#ControlByID
	GROUP BY ID
	ORDER BY 1
	*/

	IF OBJECT_ID('tempdb..#Exposed') IS NOT NULL DROP TABLE #Exposed
	SELECT	TOP 1500000
			CINID
	INTO	#Exposed
	FROM	Warehouse.Prototype.MVP_Engagement
	WHERE	CycleStart = @MinCycle
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX cix_CINID ON #Exposed (CINID)

	EXEC	Warehouse.Prototype.oo_TimerMessage ' #Exposed ', @time OUTPUT

	IF OBJECT_ID('tempdb..#ExposedByID') IS NOT NULL DROP TABLE #ExposedByID
	SELECT	d.ID,
			c.CINID,
			cm.ComboID
	INTO	#ExposedByID
	FROM	#Dates d
	CROSS JOIN #Exposed c
	JOIN	(SELECT	CINID,
					ComboID
			 FROM	Warehouse.Prototype.MVP_Engagement
			 WHERE	CycleStart = @MinCycle) cm
		ON	c.CINID = cm.CINID 

	CREATE CLUSTERED INDEX cix_CINID ON #ExposedByID (CINID)
	CREATE NONCLUSTERED INDEX nix_ComboID ON #ExposedByID (ID) INCLUDE (CINID)

	EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedByID ', @time OUTPUT

	/*
	-- Check
	SELECT	ID,
			COUNT(CINID) AS Population
	FROM	#ExposedByID
	GROUP BY ID
	ORDER BY 1
	*/

	--####################################################################
	-- SpendStretch
	IF OBJECT_ID('Tempdb..#Ventiles') IS NOT NULL DROP TABLE #Ventiles
	CREATE TABLE #Ventiles
		(
			Number INT
			,Size REAL
			,Cumulative REAL
		)

	DECLARE @i int
	DECLARE @size real

	SET @i = 0
	SET @size = 0.05

	WHILE @i <=20
		BEGIN
			INSERT INTO #Ventiles
				SELECT	@i,
						@size,
						@i*@size
							
			SET @i = @i + 1
		END

	EXEC Warehouse.Prototype.oo_TimerMessage '#Ventile', @time OUTPUT


	DECLARE @BrandID INT,
			@RowNo INT,
			@MinDate DATE,
			@MaxDate DATE

	SET @RowNo = 1
	WHILE @RowNo <= (SELECT MAX(RowNo) FROM #BrandList)
		BEGIN
		
			SET @msg = 'Loop working on #' + CAST(@RowNo AS VARCHAR(5))
			EXEC	Warehouse.Prototype.oo_TimerMessage @msg, @time OUTPUT

			-- Find Desired Variables
			SELECT	@BrandID = BrandID
			FROM	#BrandList
			WHERE	RowNo = @RowNo
		
			IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
			SELECT	ID,
					BrandID,
					AcquireDate,
					LapsedDate,
					MaxDate,
					CycleStart,
					CycleEnd,
					MonthDate
			INTO	#WorkingDates
			FROM	#BrandDates
			WHERE	BrandID = @BrandID

			-- INDEXING
			CREATE CLUSTERED INDEX cix_ID ON #WorkingDates (ID)
			CREATE NONCLUSTERED INDEX nix_AcquireLapsed ON #WorkingDates (ID) INCLUDE (AcquireDate, LapsedDate)
			CREATE NONCLUSTERED INDEX nix_LapsedShopper ON #WorkingDates (ID) INCLUDE (LapsedDate, MaxDate)
			CREATE NONCLUSTERED INDEX nix_Cycles ON #WorkingDates (ID) INCLUDE (CycleStart, CycleEnd)

			-- SELECT * FROM #WorkingDates

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #WorkingDates ', @time OUTPUT

			SELECT	@MinDate = MIN(AcquireDate),
					@MaxDate = MAX(CycleEnd)
			FROM	#WorkingDates

			EXEC	Warehouse.Prototype.oo_TimerMessage ' Performing Analysis on the 1.5m Control Group Sample ', @time OUTPUT

			-- Find all Control Group Transactions
			IF OBJECT_ID('tempdb..#ControlTrans') IS NOT NULL DROP TABLE #ControlTrans
			SELECT	ct.CINID,
					ct.Amount,
					ct.IsOnline,
					ct.TranDate
			INTO	#ControlTrans
			FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
			JOIN	#CC cc
				ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
			JOIN	#Control c
				ON	c.CINID = ct.CINID
			WHERE	cc.BrandID = @BrandID
				AND	@MinDate <= ct.TranDate AND ct.TranDate <= @MaxDate
				AND 0 < ct.Amount

			CREATE CLUSTERED INDEX cix_ControlTrans_Main ON #ControlTrans (TranDate)
			CREATE NONCLUSTERED INDEX nix_ControlTrans_Secondary ON #ControlTrans (TranDate) INCLUDE (CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlTrans ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ControlTransByID') IS NOT NULL DROP TABLE #ControlTransByID
			SELECT	ID,
					CINID,
					SUM(Amount) AS TotalSales,
					MAX(TranDate) AS LastTran
			INTO	#ControlTransByID
			FROM	#WorkingDates bd
			JOIN	#ControlTrans ct
				ON	bd.AcquireDate <= ct.TranDate AND ct.TranDate <= bd.MaxDate
			GROUP BY ID,
					CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #ControlTransByID (ID,CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlTransByID ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ControlSegments') IS NOT NULL DROP TABLE #ControlSegments
			SELECT	c.ID,
					c.CINID,
					CASE
					  WHEN bd.LapsedDate <= t.LastTran THEN 'Shopper'
					  WHEN t.LastTran < bd.LapsedDate THEN 'Lapsed'
					  ELSE 'Acquire'
					END AS Segment,
					t.TotalSales AS PropensityScore
			INTO	#ControlSegments
			FROM	#ControlByID c
			JOIN	#WorkingDates bd
				ON	c.ID = bd.ID
			LEFT JOIN #ControlTransByID t
				ON	c.ID = t.ID
				AND c.CINID = t.CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #ControlSegments (ID,CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlSegments ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ControlSegmentsNTILED') IS NOT NULL DROP TABLE #ControlSegmentsNTILED
			SELECT	ID,
					CINID,
					Segment,
					PropensityScore,
					CASE
					  WHEN Segment != 'Acquire' THEN NTILE(4) OVER (PARTITION BY ID,Segment ORDER BY PropensityScore DESC)
					  ELSE 99
					END AS PropensityRank
			INTO	#ControlSegmentsNTILED
			FROM	#ControlSegments

			CREATE CLUSTERED INDEX cix_CINID ON #ControlSegmentsNTILED (CINID)
			CREATE NONCLUSTERED INDEX nix_ComboID ON #ControlSegmentsNTILED (ID) INCLUDE (CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlSegmentsNTILED ', @time OUTPUT
		
			-- Control Topline Summary
			IF OBJECT_ID('tempdb..#ControlSummary') IS NOT NULL DROP TABLE #ControlSummary
			SELECT	a.ID,
					a.Segment,
					a.PropensityRank,
					a.Population,
					b.TotalSales,
					b.TotalTrans,
					b.TotalShoppers,
					c.OnlineSales,
					c.OnlineTrans,
					c.OnlineShoppers
			INTO	#ControlSummary
			FROM  (
					SELECT	ID,
							Segment,
							PropensityRank,
							COUNT(*) AS Population
					FROM	#ControlSegmentsNTILED
					GROUP BY ID,
							Segment,
							PropensityRank
				  ) a
			LEFT JOIN  (	
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							SUM(Amount) AS TotalSales,
							COUNT(ct.CINID) AS TotalTrans,
							COUNT(DISTINCT ct.CINID) AS TotalShoppers
					FROM	#ControlSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ControlTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank
				  ) b
				ON a.ID = b.ID
				AND	a.Segment = b.Segment
				AND a.PropensityRank = b.PropensityRank
			LEFT JOIN  (
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							SUM(Amount) AS OnlineSales,
							COUNT(ct.CINID) AS OnlineTrans,
							COUNT(DISTINCT ct.CINID) AS OnlineShoppers
					FROM	#ControlSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ControlTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					WHERE	ct.IsOnline = 1
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank
				  ) c
				ON	a.ID = c.ID
				AND	a.Segment = c.Segment
				AND a.PropensityRank = c.PropensityRank

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlSummary ', @time OUTPUT

			-- SELECT * FROM #ControlSummary ORDER BY 1,2,3

			-- Control Topline SS

			IF OBJECT_ID('tempdb..#ControlTotalSS') IS NOT NULL DROP TABLE #ControlTotalSS
			SELECT	ID,
					Amount,
					Sales,
					SUM(Sales) OVER (PARTITION BY ID) AS TotalSales,
					1.0*Sales/(SUM(Sales) OVER (PARTITION BY ID)) AS PercentageSales
			INTO	#ControlTotalSS
			FROM	(
						SELECT	c.ID,
								ROUND(ct.Amount,0) AS Amount,
								SUM(ct.Amount) AS Sales
						FROM	#ControlSegmentsNTILED c
						JOIN	#WorkingDates bd
							ON	c.ID = bd.ID
						JOIN	#ControlTrans ct
							ON	c.CINID = ct.CINID
							AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
						-- WHERE	Segment = 'Acquire'
						GROUP BY c.ID,
								ROUND(ct.Amount,0)
					) a

			IF OBJECT_ID('tempdb..#ControlTotalCumulativeSS') IS NOT NULL DROP TABLE #ControlTotalCumulativeSS
			SELECT	a.ID,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales,
					1.0000*SUM(b.Sales)/a.TotalSales as CumulativePercentageSales
			INTO	#ControlTotalCumulativeSS
			FROM	#ControlTotalSS a
			JOIN	#ControlTotalSS b
				ON	a.ID = b.ID
				AND a.Amount >= b.Amount
			GROUP BY a.ID,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales
		
			--	Output
			IF OBJECT_ID('tempdb..#ControlTotalBoundarys') IS NOT NULL DROP TABLE #ControlTotalBoundarys
			SELECT	@BrandID AS BrandID,
					ID,
					Cumulative,
					MIN(Amount) AS Boundary
			INTO	#ControlTotalBoundarys
			FROM	#Ventiles a
			JOIN	#ControlTotalCumulativeSS b
				ON	b.CumulativePercentageSales >= a.Cumulative
			GROUP BY ID,
					 Cumulative
			ORDER BY 1,2,3

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlTotalBoundarys ', @time OUTPUT

			-- Control Propensity SS

			IF OBJECT_ID('tempdb..#ControlPropensitySS') IS NOT NULL DROP TABLE #ControlPropensitySS
			SELECT	ID,
					PropensityRank,
					Amount,
					Sales,
					SUM(Sales) OVER (PARTITION BY ID, PropensityRank) AS TotalSales,
					1.0*Sales/(SUM(Sales) OVER (PARTITION BY ID, PropensityRank)) AS PercentageSales
			INTO	#ControlPropensitySS
			FROM	(
						SELECT	c.ID,
								c.PropensityRank,
								ROUND(ct.Amount,0) AS Amount,
								SUM(ct.Amount) AS Sales
						FROM	#ControlSegmentsNTILED c
						JOIN	#WorkingDates bd
							ON	c.ID = bd.ID
						JOIN	#ControlTrans ct
							ON	c.CINID = ct.CINID
							AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
						GROUP BY c.ID,
								c.PropensityRank,
								ROUND(ct.Amount,0)
					) a

			IF OBJECT_ID('tempdb..#ControlPropensityCumulativeSS') IS NOT NULL DROP TABLE #ControlPropensityCumulativeSS
			SELECT	a.ID,
					a.PropensityRank,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales,
					1.0000*SUM(b.Sales)/a.TotalSales as CumulativePercentageSales
			INTO	#ControlPropensityCumulativeSS
			FROM	#ControlPropensitySS a
			JOIN	#ControlPropensitySS b
				ON	a.ID = b.ID
				AND	a.PropensityRank = b.PropensityRank
				AND a.Amount >= b.Amount
			GROUP BY a.ID,
					a.PropensityRank,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales

			IF OBJECT_ID('tempdb..#ControlPropensityBoundarys') IS NOT NULL DROP TABLE #ControlPropensityBoundarys
			SELECT	@BrandID AS BrandID,
					ID,
					PropensityRank,
					Cumulative,
					MIN(Amount) AS Boundary
			INTO	#ControlPropensityBoundarys
			FROM	#Ventiles a
			JOIN	#ControlPropensityCumulativeSS b
				ON	b.CumulativePercentageSales >= a.Cumulative
			GROUP BY ID,
					 PropensityRank,
					 Cumulative
			ORDER BY 1,2,3,4

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ControlPropensityBoundarys ', @time OUTPUT
		
			-----------------------------------------------------------------------------------------------------------------
			EXEC	Warehouse.Prototype.oo_TimerMessage ' Performing Analysis on the 1.5m Exposed Group Sample ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ExposedTrans') IS NOT NULL DROP TABLE #ExposedTrans
			SELECT	ct.CINID,
					ct.Amount,
					ct.IsOnline,
					ct.TranDate,
					ct.PaymentTypeID
			INTO	#ExposedTrans
			FROM	Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
			JOIN	#CC cc
				ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
			JOIN	#Exposed c
				ON	c.CINID = ct.CINID
			WHERE	cc.BrandID = @BrandID
				AND	@MinDate <= ct.TranDate AND ct.TranDate <= @MaxDate
				AND 0 < ct.Amount

			CREATE CLUSTERED INDEX cix_ControlTrans_Main ON #ExposedTrans (TranDate)
			CREATE NONCLUSTERED INDEX nix_ControlTrans_Secondary ON #ExposedTrans (TranDate) INCLUDE (CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedTrans ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ExposedTransByID') IS NOT NULL DROP TABLE #ExposedTransByID
			SELECT	ID,
					CINID,
					SUM(Amount) AS TotalSales,
					MAX(TranDate) AS LastTran
			INTO	#ExposedTransByID
			FROM	#WorkingDates bd
			JOIN	#ExposedTrans ct
				ON	bd.AcquireDate <= ct.TranDate AND ct.TranDate <= bd.MaxDate
			GROUP BY ID,
					CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #ExposedTransByID (ID,CINID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedTransByID ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ExposedSegments') IS NOT NULL DROP TABLE #ExposedSegments
			SELECT	c.ID,
					c.CINID,
					CASE
					  WHEN bd.LapsedDate <= t.LastTran THEN 'Shopper'
					  WHEN t.LastTran < bd.LapsedDate THEN 'Lapsed'
					  ELSE 'Acquire'
					END AS Segment,
					COALESCE(t.TotalSales,h.Index_RR) AS PropensityScore
			INTO	#ExposedSegments
			FROM	#ExposedByID c
			JOIN	#WorkingDates bd
				ON	c.ID = bd.ID
			LEFT JOIN
				(
					SELECT	BrandID,
							ComboID,
							Index_RR
					FROM	Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index
					WHERE	BrandID = @BrandID
				) h
				ON	c.ComboID = h.ComboID
			LEFT JOIN #ExposedTransByID t
				ON	c.ID = t.ID
				AND c.CINID = t.CINID

			--SELECT TOP 100 * FROM #ExposedSegments

			CREATE CLUSTERED INDEX cix_ComboID ON #ExposedSegments (ID,CINID)
			CREATE NONCLUSTERED INDEX nix_CINID ON #ExposedSegments (CINID)
			CREATE NONCLUSTERED INDEX nix_ID ON #ExposedSegments (ID)

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedSegments ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ExposedSegmentsNTILED') IS NOT NULL DROP TABLE #ExposedSegmentsNTILED
			SELECT	c.ID,
					c.CINID,
					c.Segment,
					c.PropensityScore,
					NTILE(4) OVER (PARTITION BY c.ID,c.Segment ORDER BY c.PropensityScore DESC) AS PropensityRank,
					COALESCE(e.EngagementRank,4) AS EngagementRank
			INTO	#ExposedSegmentsNTILED
			FROM	#ExposedSegments c
			JOIN	#WorkingDates db
				ON	c.ID = db.ID
			LEFT JOIN	Warehouse.Prototype.MVP_Engagement e
				ON	db.CycleStart = e.CycleStart
				AND	c.CINID = e.CINID

			CREATE CLUSTERED INDEX cix_CINID ON #ExposedSegmentsNTILED (CINID)
			CREATE NONCLUSTERED INDEX nix_ComboID ON #ExposedSegmentsNTILED (ID) INCLUDE (CINID)

			/*
			SELECT	ID,
					EngagementRank,
					COUNT(CINID)
			FROM	#ExposedSegmentsNTILED
			GROUP BY ID,
					EngagementRank
			ORDER BY 1,2
			*/

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedSegmentsNTILED ', @time OUTPUT
		
			-- Exposed Topline Summary
			IF OBJECT_ID('tempdb..#ExposedSummary_woCC') IS NOT NULL DROP TABLE #ExposedSummary_woCC
			SELECT	a.ID,
					a.Segment,
					a.PropensityRank,
					a.EngagementRank,
					a.Population,
					b.TotalSales,
					b.TotalTrans,
					b.TotalShoppers,
					c.OnlineSales,
					c.OnlineTrans,
					c.OnlineShoppers
			INTO	#ExposedSummary_woCC
			FROM  (
					SELECT	ID,
							Segment,
							PropensityRank,
							EngagementRank,
							COUNT(*) AS Population
					FROM	#ExposedSegmentsNTILED
					GROUP BY ID,
							Segment,
							PropensityRank,
							EngagementRank
				  ) a  
			LEFT JOIN	  (
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank,
							SUM(Amount) AS TotalSales,
							COUNT(ct.CINID) AS TotalTrans,
							COUNT(DISTINCT ct.CINID) AS TotalShoppers
					FROM	#ExposedSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ExposedTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					WHERE	ct.PaymentTypeID = 1
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank
				  ) b
				ON	a.ID = b.ID
				AND	a.Segment = b.Segment
				AND a.PropensityRank = b.PropensityRank
				AND	a.EngagementRank = b.EngagementRank
			LEFT JOIN  (
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank,
							SUM(Amount) AS OnlineSales,
							COUNT(ct.CINID) AS OnlineTrans,
							COUNT(DISTINCT ct.CINID) AS OnlineShoppers
					FROM	#ExposedSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ExposedTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					WHERE	ct.IsOnline = 1
						AND	ct.PaymentTypeID = 1
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank
				  ) c
				ON	a.ID = c.ID
				AND	a.Segment = c.Segment
				AND a.PropensityRank = c.PropensityRank
				AND	a.EngagementRank = c.EngagementRank

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedSummary_woCC ', @time OUTPUT

			IF OBJECT_ID('tempdb..#ExposedSummary_wCC') IS NOT NULL DROP TABLE #ExposedSummary_wCC
			SELECT	a.ID,
					a.Segment,
					a.PropensityRank,
					a.EngagementRank,
					a.Population,
					b.TotalSales,
					b.TotalTrans,
					b.TotalShoppers,
					c.OnlineSales,
					c.OnlineTrans,
					c.OnlineShoppers
			INTO	#ExposedSummary_wCC
			FROM  (
					SELECT	ID,
							Segment,
							PropensityRank,
							EngagementRank,
							COUNT(*) AS Population
					FROM	#ExposedSegmentsNTILED
					GROUP BY ID,
							Segment,
							PropensityRank,
							EngagementRank
				  ) a
			LEFT JOIN (
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank,
							SUM(Amount) AS TotalSales,
							COUNT(ct.CINID) AS TotalTrans,
							COUNT(DISTINCT ct.CINID) AS TotalShoppers
					FROM	#ExposedSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ExposedTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank
				  ) b
				ON	a.ID = b.ID
				AND	a.Segment = b.Segment
				AND a.PropensityRank = b.PropensityRank
				AND	a.EngagementRank = b.EngagementRank
			LEFT JOIN  (
					SELECT	c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank,
							SUM(Amount) AS OnlineSales,
							COUNT(ct.CINID) AS OnlineTrans,
							COUNT(DISTINCT ct.CINID) AS OnlineShoppers
					FROM	#ExposedSegmentsNTILED c
					JOIN	#WorkingDates bd
						ON	c.ID = bd.ID
					LEFT JOIN #ExposedTrans ct
						ON	c.CINID = ct.CINID
						AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
					WHERE	ct.IsOnline = 1
					GROUP BY c.ID,
							c.Segment,
							c.PropensityRank,
							c.EngagementRank
				  ) c
				ON	a.ID = c.ID
				AND	a.Segment = c.Segment
				AND a.PropensityRank = c.PropensityRank
				AND	a.EngagementRank = c.EngagementRank

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedSummary_wCC ', @time OUTPUT

			-- Control Topline SS

			IF OBJECT_ID('tempdb..#ExposedTotalSS') IS NOT NULL DROP TABLE #ExposedTotalSS
			SELECT	ID,
					Amount,
					Sales,
					SUM(Sales) OVER (PARTITION BY ID) AS TotalSales,
					1.0*Sales/(SUM(Sales) OVER (PARTITION BY ID)) AS PercentageSales
			INTO	#ExposedTotalSS
			FROM	(
						SELECT	c.ID,
								ROUND(ct.Amount,0) AS Amount,
								SUM(ct.Amount) AS Sales
						FROM	#ExposedSegmentsNTILED c
						JOIN	#WorkingDates bd
							ON	c.ID = bd.ID
						JOIN	#ExposedTrans ct
							ON	c.CINID = ct.CINID
							AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
						-- WHERE	Segment = 'Acquire'
						GROUP BY c.ID,
								ROUND(ct.Amount,0)
					) a

			IF OBJECT_ID('tempdb..#ExposedTotalCumulativeSS') IS NOT NULL DROP TABLE #ExposedTotalCumulativeSS
			SELECT	a.ID,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales,
					1.0000*SUM(b.Sales)/a.TotalSales as CumulativePercentageSales
			INTO	#ExposedTotalCumulativeSS
			FROM	#ExposedTotalSS a
			JOIN	#ExposedTotalSS b
				ON	a.ID = b.ID
				AND a.Amount >= b.Amount
			GROUP BY a.ID,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales
		
			--	Output
			IF OBJECT_ID('tempdb..#ExposedTotalBoundarys') IS NOT NULL DROP TABLE #ExposedTotalBoundarys
			SELECT	@BrandID AS BrandID,
					ID,
					Cumulative,
					MIN(Amount) AS Boundary
			INTO	#ExposedTotalBoundarys
			FROM	#Ventiles a
			JOIN	#ExposedTotalCumulativeSS b
				ON	b.CumulativePercentageSales >= a.Cumulative
			GROUP BY ID,
					 Cumulative
			ORDER BY 1,2,3

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedTotalBoundarys ', @time OUTPUT

			-- Control Propensity SS

			IF OBJECT_ID('tempdb..#ExposedPropensitySS') IS NOT NULL DROP TABLE #ExposedPropensitySS
			SELECT	ID,
					PropensityRank,
					Amount,
					Sales,
					SUM(Sales) OVER (PARTITION BY ID, PropensityRank) AS TotalSales,
					1.0*Sales/(SUM(Sales) OVER (PARTITION BY ID, PropensityRank)) AS PercentageSales
			INTO	#ExposedPropensitySS
			FROM	(
						SELECT	c.ID,
								c.PropensityRank,
								ROUND(ct.Amount,0) AS Amount,
								SUM(ct.Amount) AS Sales
						FROM	#ExposedSegmentsNTILED c
						JOIN	#WorkingDates bd
							ON	c.ID = bd.ID
						JOIN	#ExposedTrans ct
							ON	c.CINID = ct.CINID
							AND	bd.CycleStart <= ct.TranDate AND ct.TranDate <= bd.CycleEnd
						GROUP BY c.ID,
								c.PropensityRank,
								ROUND(ct.Amount,0)
					) a

			IF OBJECT_ID('tempdb..#ExposedPropensityCumulativeSS') IS NOT NULL DROP TABLE #ExposedPropensityCumulativeSS
			SELECT	a.ID,
					a.PropensityRank,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales,
					1.0000*SUM(b.Sales)/a.TotalSales as CumulativePercentageSales
			INTO	#ExposedPropensityCumulativeSS
			FROM	#ExposedPropensitySS a
			JOIN	#ExposedPropensitySS b
				ON	a.ID = b.ID
				AND	a.PropensityRank = b.PropensityRank
				AND a.Amount >= b.Amount
			GROUP BY a.ID,
					a.PropensityRank,
					a.Amount,
					a.Sales,
					a.TotalSales,
					a.PercentageSales

			IF OBJECT_ID('tempdb..#ExposedPropensityBoundarys') IS NOT NULL DROP TABLE #ExposedPropensityBoundarys
			SELECT	@BrandID AS BrandID,
					ID,
					PropensityRank,
					Cumulative,
					MIN(Amount) AS Boundary
			INTO	#ExposedPropensityBoundarys
			FROM	#Ventiles a
			JOIN	#ExposedPropensityCumulativeSS b
				ON	b.CumulativePercentageSales >= a.Cumulative
			GROUP BY ID,
					 PropensityRank,
					 Cumulative
			ORDER BY 1,2,3,4

			EXEC	Warehouse.Prototype.oo_TimerMessage ' #ExposedPropensityBoundarys ', @time OUTPUT

			-- Collate Outputs
			INSERT INTO	Warehouse.Prototype.MVP_NaturalSalesByCycle
				SELECT	GETDATE() AS RunDate,
						'Control' AS GroupName,
						@BrandID AS BrandID,
						a.ID,
						b.Seasonality_CycleID,
						Segment,
						PropensityRank,
						NULL AS EngagementRank,
						Population,
						TotalSales,
						OnlineSales,
						TotalTrans,
						OnlineTrans,
						TotalShoppers,
						OnlineShoppers
				FROM	#ControlSummary a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID
		
			INSERT INTO	Warehouse.Prototype.MVP_NaturalSalesByCycle
				SELECT	GETDATE() AS RunDate,
						'Exposed - with Credit' AS GroupName,
						@BrandID AS BrandID,
						a.ID,
						b.Seasonality_CycleID,
						Segment,
						PropensityRank,
						EngagementRank,
						Population,
						TotalSales,
						OnlineSales,
						TotalTrans,
						OnlineTrans,
						TotalShoppers,
						OnlineShoppers
				FROM	#ExposedSummary_wCC a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID

			INSERT INTO	Warehouse.Prototype.MVP_NaturalSalesByCycle
				SELECT	GETDATE() AS RunDate,
						'Exposed - Debit' AS GroupName,
						@BrandID AS BrandID,
						a.ID,
						b.Seasonality_CycleID,
						Segment,
						PropensityRank,
						EngagementRank,
						Population,
						TotalSales,
						OnlineSales,
						TotalTrans,
						OnlineTrans,
						TotalShoppers,
						OnlineShoppers
				FROM	#ExposedSummary_woCC a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID

			-- Total SS
			INSERT INTO	Warehouse.Prototype.MVP_SpendStretchTotal
				SELECT	GETDATE() AS RunDate,
						'Control' AS GroupType,
						BrandID,
						a.ID,
						b.Seasonality_CycleID,
						Cumulative,
						Boundary
				FROM	#ControlTotalBoundarys a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID
		
			INSERT INTO	Warehouse.Prototype.MVP_SpendStretchTotal
				SELECT	GETDATE() AS RunDate,
						'Exposed - with Credit' AS GroupType,
						BrandID,
						a.ID,
						b.Seasonality_CycleID,
						Cumulative,
						Boundary
				FROM	#ExposedTotalBoundarys a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID

			-- Propensity SS
			INSERT INTO	Warehouse.Prototype.MVP_SpendStretchPropensityRank
				SELECT	GETDATE() AS RunDate,
						'Control' AS GroupType,
						BrandID,
						a.ID,
						b.Seasonality_CycleID,
						PropensityRank,
						Cumulative,
						Boundary
				FROM	#ControlPropensityBoundarys a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID

			INSERT INTO Warehouse.Prototype.MVP_SpendStretchPropensityRank
				SELECT	GETDATE() AS RunDate,
						'Exposed - with Credit' AS GroupType,
						BrandID,
						a.ID,
						b.Seasonality_CycleID,
						PropensityRank,
						Cumulative,
						Boundary
				FROM	#ExposedPropensityBoundarys a
				JOIN	Warehouse.Prototype.MVP_DateTable b
					ON	a.ID = b.ID

			-- Iterate
			SET @RowNo = @RowNo + 1
		END

		--IF OBJECT_ID('Warehouse.Prototype.MVP_NaturalSalesByCycle') IS NOT NULL DROP TABLE Warehouse.Prototype.MVP_NaturalSalesByCycle
		--CREATE TABLE Warehouse.Prototype.MVP_NaturalSalesByCycle
		--	(
		--		PKID INT IDENTITY(1,1) PRIMARY KEY,
		--		RunDate DATE,
		--		GroupName VARCHAR(50),
		--		BrandID INT,
		--		ID INT,
		--		Seasonality_CycleID INT,
		--		Segment VARCHAR(20),
		--		PropensityRank TINYINT,
		--		EngagementRank TINYINT,
		--		Population INT,
		--		TotalSales MONEY,
		--		OnlineSales MONEY,
		--		TotalTrans INT,
		--		OnlineTrans INT,
		--		TotalShoppers INT,
		--		OnlineShoppers INT
		--	)

		--IF OBJECT_ID('Warehouse.Prototype.MVP_SpendStretchTotal') IS NOT NULL DROP TABLE Warehouse.Prototype.MVP_SpendStretchTotal
		--CREATE TABLE Warehouse.Prototype.MVP_SpendStretchTotal
		--	(
		--		PKID INT IDENTITY(1,1) PRIMARY KEY,
		--		RunDate DATE,
		--		GroupName VARCHAR(50),
		--		BrandID INT,
		--		ID INT,
		--		Seasonality_CycleID INT,
		--		CumulativePercentage DECIMAL(3,2),
		--		Boundary MONEY
		--	)

		--IF OBJECT_ID('Warehouse.Prototype.MVP_SpendStretchPropensityRank') IS NOT NULL DROP TABLE Warehouse.Prototype.MVP_SpendStretchPropensityRank
		--CREATE TABLE Warehouse.Prototype.MVP_SpendStretchPropensityRank
		--	(
		--		PKID INT IDENTITY(1,1) PRIMARY KEY,
		--		RunDate DATE,
		--		GroupName VARCHAR(50),
		--		BrandID INT,
		--		ID INT,
		--		Seasonality_CycleID INT,
		--		PropensityRank TINYINT,
		--		CumulativePercentage DECIMAL(3,2),
		--		Boundary MONEY
		--	)





END
