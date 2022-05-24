-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <24th January 2019>
-- Description:	<Rehashed version of Natural Sales Script to facilitate bulk running
-- of refresh and utilising the indexing of ConsumerTransaction_MyRewards>
-- updated dates to reflect late 2020 transactions
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_TEST_NaturalSalesByCycle_Calculate_MorrisonsStIves]
	@BrandList VARCHAR(500),
	@Bespoke BIT = 0,
	@TableName VARCHAR(500) = NULL,
	@AcquireL INT = NULL,
	@LapsedL INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Prevent table locks forming
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Start', @time OUTPUT

	----------------------------------------------------------------------------------
	-- Produce Brand(s) List that needs refreshing
	
	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(	
			BrandID INT,
			BrandName VARCHAR(50)
		)

	IF @BrandList IS NULL
		BEGIN	
			INSERT INTO #Brand
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	CREATE CLUSTERED INDEX cix_BrandID ON #Brand (BrandID)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #Brand', @time OUTPUT

	DECLARE @BrandCount INT = (SELECT COUNT(*) FROM #Brand)

		-- Test for Errors
	IF @Bespoke = 1
		BEGIN
			IF @TableName IS NULL 
			  BEGIN
				RAISERROR ('Error #1 --- You need to supply a table name in a bespoke forecast', 0, 1) WITH NOWAIT
				RETURN
			  END
			ELSE
				BEGIN
					IF (@AcquireL IS NOT NULL AND @LapsedL IS NULL) OR (@AcquireL IS NULL AND @LapsedL IS NOT NULL)
					  BEGIN
						RAISERROR ('Error #2 --- If you are specifying segment lengths, you must always specify both.', 0, 1) WITH NOWAIT
						RETURN
					  END
					IF 1 < @BrandCount
					  BEGIN
						RAISERROR ('Error #3 --- Bespoke Forecasting requires a single brand.', 0, 1) WITH NOWAIT
						RETURN
					  END
				END
		END


	----------------------------------------------------------------------------------
	-- Find relevant ConsumerCombinationIDs

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	SELECT	cc.BrandID,
			cc.ConsumerCombinationID
	INTO	#CC
	FROM	Warehouse.Relational.ConsumerCombination cc WITH (NOLOCK)
	JOIN	#Brand br
		ON	cc.BrandID = br.BrandID
	WHERE (MID LIKE '%06022320%'
	OR MID LIKE '%06022319%'
	OR MID LIKE '%6022320%'
	OR MID LIKE '%6022319%'
	OR MID LIKE '%8022059%')

	CREATE CLUSTERED INDEX cix_ConsumerCombination ON #CC (BrandID, ConsumerCombinationID)
	-- (879,656 rows affected) / 00:00:03

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #CC', @time OUTPUT

	----------------------------------------------------------------------------------
	-- Find a 1.5m sample set of customers

	IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
	CREATE TABLE #Customer
		(	
			CINID INT
		)

	IF @Bespoke = 1
		BEGIN
			EXEC('
					INSERT INTO #Customer
						SELECT	CINID
						FROM	' + @TableName + '
			')
		END
	ELSE
		BEGIN
			INSERT INTO #Customer
				SELECT	TOP 1500000 *
				FROM	(
							SELECT	CINID
							FROM	Warehouse.Relational.Customer c
							JOIN	Warehouse.Relational.CINList cl
								ON	cl.CIN = c.SourceUID
							WHERE	c.CurrentlyActive = 1
								AND NOT EXISTS
									(
										SELECT	*
										FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
										WHERE	EndDate IS NULL
											AND c.SourceUID = dup.SourceUID
									)
						) a
				-- ORDER BY CINID -- Enable for TESTING purposes
				ORDER BY NEWID() -- Disable for TESTING purposes
		END

	CREATE CLUSTERED INDEX cix_CINID ON #Customer (CINID)

	-- (1500000 rows affected) / 00:00:09

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #Customer', @time OUTPUT
	
	DECLARE @TotalCustomers INT = (SELECT COUNT(*) FROM #Customer)

	----------------------------------------------------------------------------------
	-- Dates CTE

	IF OBJECT_ID('tempdb..#Dates') IS NOT NULL DROP TABLE #Dates
	CREATE TABLE #Dates
		(
			ID INT NOT NULL PRIMARY KEY
			,CycleStart DATE
			,CycleEnd DATE
			,Seasonality_CycleID INT
		)

	;WITH CTE
	 AS (	
			SELECT	1 AS ID
					,CAST('2017-03-30' AS DATE) AS CycleStart
					,CAST('2017-04-26' AS DATE) AS CycleEnd
					,4 AS Seasonality_CycleID
		
			UNION ALL
		
			SELECT	ID + 1
					,CAST(DATEADD(DAY,28,CycleStart) AS DATE)
					,CAST(DATEADD(DAY,28,CycleEnd) AS DATE)
					,CASE
						WHEN Seasonality_CycleID < 13 THEN Seasonality_CycleID + 1
						ELSE Seasonality_CycleID - 12
					 END
			FROM	CTE
			WHERE	ID < 68
		)
	INSERT INTO #Dates
		SELECT	* 
		FROM	CTE
	OPTION (MAXRECURSION 68)
	-- (68 rows affected) / 00:00:01

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #Dates', @time OUTPUT


	----------------------------------------------------------------------------------
	-- Dates Subsetted - Most Recent allowing for Transactional Lag
	
	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT	b.*
			,ROW_NUMBER() OVER (ORDER BY b.ID ASC) AS DateRow
	INTO	#WorkingDates
	FROM	(SELECT	*
			 FROM	#Dates 
			 WHERE	CycleStart <= CAST(DATEADD(DAY,-7,GETDATE()) AS DATE)
				AND CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) <= CycleEnd) a
	JOIN	#Dates b
		ON  a.ID - 15 < b.ID
		AND b.ID < a.ID

	CREATE CLUSTERED INDEX cix_DateRow ON #WorkingDates(DateRow)
	--CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	--CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)
	-- (14 rows affected) / 00:00:00

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #WorkingDates', @time OUTPUT


	----------------------------------------------------------------------------------
	-- Segment Lengths

	IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	SELECT	br.BrandName
			,br.BrandID
			,COALESCE(part.Acquire,blk.acquireL,lk.AcquireL,12) as AcquireL
			,COALESCE(part.Lapsed,blk.LapserL,lk.LapserL,6) as LapserL
			,br.SectorID
	INTO	#Settings
	FROM	Warehouse.Relational.Brand br
	LEFT JOIN	
		(		SELECT	DISTINCT p.BrandID,
						part.Acquire,
						part.Lapsed
				FROM	Warehouse.Relational.Partner p
				JOIN	Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings part
					ON	p.PartnerID = part.PartnerID
				WHERE	EndDate IS NULL
		) part
		ON	br.BrandID = part.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_BrandSegmentLengthOverride blk 
			on	br.BrandID = blk.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_SectorSegmentLengthOverride lk 
			on	br.SectorID = lk.SectorID
	JOIN	#Brand b
		ON	br.BrandID = b.BrandID

	CREATE CLUSTERED INDEX cix_BrandID ON #Settings (BrandID)
	-- (450 rows affected) / 00:00:01

	UPDATE s
	SET	AcquireL = 60
	FROM #Settings s
	WHERE 60 < AcquireL

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #Settings', @time OUTPUT
		
	-- Apply Bespoke Filters
	IF @AcquireL IS NOT NULL AND @LapsedL IS NOT NULL
		BEGIN
			UPDATE s
			SET AcquireL = @AcquireL,
				LapserL = @LapsedL
			FROM #Settings s
		END

	-- Test if single brand, print out segment settings if so.
	IF @BrandCount = 1
		BEGIN
			SELECT * FROM #Settings
			
			SELECT	'CustomerCount', @TotalCustomers AS CustomerCount
		END

	----------------------------------------------------------------------------------
	-- Date Table + Segment Lengths

	IF OBJECT_ID('tempdb..#JoinDates') IS NOT NULL DROP TABLE #JoinDates
	SELECT	ID,
			BrandID,
			CAST(DATEADD(MONTH,-b.AcquireL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS AcquireDate,
			CAST(DATEADD(MONTH,-b.LapserL,DATEADD(DAY,-1,CycleStart)) AS DATE) AS LapsedDate,
			CAST(DATEADD(DAY,-1,CycleStart) AS DATE) AS MaxDate,
			CycleStart,
			CycleEnd,
			Seasonality_CycleID,
			DateRow
	INTO	#JoinDates
	FROM	#WorkingDates a
	CROSS JOIN #Settings b

	CREATE CLUSTERED INDEX cix_ID ON #JoinDates (DateRow, BrandID)

	-- (6300 rows affected) / 00:00:00

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #JoinDates', @time OUTPUT

-- ===============================================================================================================================
--------------------------------------------------------------------------------------------------------------------------------
	-- Pull Transaction Data To Segment Customers
	DECLARE @MinDate DATE,
			@MaxDate DATE
	SELECT	@MinDate = MIN(AcquireDate),
			@MaxDate = MAX(MaxDate)
	FROM	#JoinDates
	WHERE	DateRow = 1

	IF OBJECT_ID('tempdb..#InitialSegmentation') IS NOT NULL DROP TABLE #InitialSegmentation
	SELECT	lt.BrandID,
			lt.CINID,
			lt.LastTransactionDate,
			x.CurrentSegmentation,
			0 AS NewSegmentation
	INTO #InitialSegmentation
	FROM (SELECT * FROM #JoinDates WHERE DateRow = 1) d -- 450 rows
	CROSS APPLY (
		SELECT	cc.BrandID,
				ct.CINID,
				MAX(TranDate) AS LastTransactionDate
		FROM Warehouse.Relational.ConsumerTransaction_MyRewards ct WITH (NOLOCK)
		INNER JOIN #CC cc 
			ON ct.ConsumerCombinationID = cc.ConsumerCombinationID
		JOIN #Customer c
			ON ct.CINID = c.CINID
		WHERE cc.BrandID = d.BrandID  
			AND 0 < ct.Amount
			AND	@MinDate <= ct.TranDate AND ct.TranDate <= @MaxDate
		GROUP BY cc.BrandID,
				 ct.CINID
	) lt
	CROSS APPLY (
		SELECT CurrentSegmentation = CASE
			  WHEN lt.LastTransactionDate < d.AcquireDate THEN 7
	          WHEN d.AcquireDate <= lt.LastTransactionDate AND lt.LastTransactionDate < d.LapsedDate THEN 8
			  ELSE 9
			END
	) x
	WHERE x.CurrentSegmentation <> 7

	CREATE CLUSTERED INDEX cix_BrandID_CINID ON #InitialSegmentation (BrandID,CINID)
	-- (37,878,677 rows affected) / 00:03:05

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #InitialSegmentation', @time OUTPUT

---------------------------------------------------------------------------------------------
-- 14 loops, one for each cycle in #WorkingDates
---------------------------------------------------------------------------------------------
	IF OBJECT_ID('tempdb..#SegmentOutput') IS NOT NULL DROP TABLE #SegmentOutput -- results table
		CREATE TABLE #SegmentOutput 
			(DateRow INT, BrandID INT, Segment INT, Sales MONEY, OnlineSales MONEY, Transactions INT, OnlineTransactions INT, Shoppers INT, OnlineShoppers INT)

	IF OBJECT_ID('tempdb..#SegmentSize') IS NOT NULL DROP TABLE #SegmentSize
		CREATE TABLE #SegmentSize
			(DateRow INT, BrandID INT, Segment INT, Population INT)
	
	IF OBJECT_ID('tempdb..#SegmentDemotions') IS NOT NULL DROP TABLE #SegmentDemotions -- results table
		CREATE TABLE #SegmentDemotions
			(DateRow INT, BrandID INT, CurrentSegmentation INT, NewSegmentation INT, Demotion INT)

	DECLARE @i INT = 1
	DECLARE @CycleStartDate DATE,
			@CycleEndDate DATE,
			@msg VARCHAR(100)

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Loop Start', @time OUTPUT


	WHILE @i <= 14 BEGIN -- ######################################################################################## LOOP START
		
		SET @msg = 'ROCEFT - NaturalSalesByCycle Loop ' + CAST(@i AS VARCHAR(2)) + ' Started'
		EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			
		SELECT	@CycleStartDate = CycleStart,
				@CycleEndDate = CycleEnd
		FROM	#WorkingDates
		WHERE	DateRow = @i
			
		---- One date cycle into #CINTrans
		IF OBJECT_ID('tempdb..#CINTrans') IS NOT NULL DROP TABLE #CINTrans
		SELECT	cc.BrandID
				,ct.CINID
				,ct.IsOnline
				,Amount = sum(ct.Amount)
				,TranDate = MAX(ct.TranDate)
				,TranCount = COUNT(*)
		INTO #CINTrans
		FROM #Customer mrb
		INNER hash JOIN #CC cc
		inner hash JOIN	Warehouse.Relational.ConsumerTransaction_MyRewards ct
			ON	ct.ConsumerCombinationID = cc.ConsumerCombinationID
			ON	ct.CINID = mrb.CINID
		WHERE 0 < ct.Amount
			AND	@CycleStartDate <= ct.TranDate AND ct.TranDate <= @CycleEndDate
		GROUP BY cc.BrandID
				,ct.CINID
				,ct.IsOnline

		CREATE CLUSTERED INDEX cix_Brand_CINID ON #CinTrans (BrandID, CINID)
		---- (9,839,982 rows affected) / 00:00:20

		EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #CINTrans ', @time OUTPUT


		-- first use of #CINTrans
		INSERT INTO #SegmentOutput -- ################## OUTPUT		
			SELECT @i AS DateRow,
				ct.BrandID,
				x.Segment,
				SUM(ct.Amount) AS Sales,
				SUM(CASE WHEN ct.IsOnline = 1 THEN ct.Amount ELSE 0 END) AS OnlineSales,
				SUM(ct.TranCount) AS Transactions,
				SUM(CASE WHEN ct.IsOnline = 1 THEN ct.TranCount ELSE 0 END) AS OnlineTransactions,
				COUNT(DISTINCT ct.CINID) AS Shoppers,
				COUNT(DISTINCT CASE WHEN ct.IsOnline = 1 THEN ct.CINID ELSE NULL END) AS OnlineShoppers
			FROM #CINTrans ct
			left JOIN #InitialSegmentation  b 
				ON	ct.BrandID = b.BrandID
				AND	ct.CINID = b.CINID
			CROSS APPLY ( -- Acquire = 7
				SELECT Segment = ISNULL(b.CurrentSegmentation, 7)
			) x
			GROUP BY ct.BrandID, x.Segment
		-- (1320 rows affected) / 00:00:05

		EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #SegmentOutput ', @time OUTPUT

		INSERT INTO #SegmentSize
			SELECT	@i as DateRow,
					BrandID,
					CurrentSegmentation,
					COUNT(1) AS Size
			FROM	#InitialSegmentation
			GROUP BY BrandID,
					CurrentSegmentation

		EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #SegmentSize', @time OUTPUT

			
		IF @i < 14 BEGIN  -- ########################################## BLOCK START

			-- second use of #CINTrans, Find new LastTransactionDate  
			IF OBJECT_ID('tempdb..#CycleLastTranDate') IS NOT NULL DROP TABLE #CycleLastTranDate
			SELECT	BrandID,
					CINID,
					MAX(TranDate) AS LastTransactionDate
			INTO	#CycleLastTranDate
			FROM	#CINTrans
			GROUP BY BrandID,
						CINID

			CREATE UNIQUE CLUSTERED INDEX cix_BrandID_CINID ON #CycleLastTranDate (BrandID, CINID)
			-- (9609277 rows affected) / 00:00:10

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- #CycleLastTranDate ', @time OUTPUT


			-- Sort out the segmentation for next cycle
			-- Update to new LastTransactionDate
			UPDATE inti SET		
				LastTransactionDate = cl.LastTransactionDate
			FROM #InitialSegmentation inti
			INNER MERGE JOIN #CycleLastTranDate cl
				ON inti.BrandID = cl.BrandID
				AND	inti.CINID = cl.CINID
			-- (7641476 rows affected) / 00:00:21

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Update LastTransactionDate ', @time OUTPUT


			-- Calculate Demotions  ################# OUTPUT
			INSERT INTO #SegmentDemotions
				SELECT	@i AS DateRow,
						inti.BrandID,
						CurrentSegmentation,
						x.NewSegmentation,
						COUNT(CINID) AS Demotion
				FROM #InitialSegmentation inti
				JOIN #JoinDates d
					ON inti.BrandID = d.BrandID
					AND	d.DateRow = (@i + 1)
				CROSS APPLY (
					SELECT NewSegmentation = CASE
						WHEN inti.LastTransactionDate < d.AcquireDate THEN 7
						WHEN d.AcquireDate <= inti.LastTransactionDate AND inti.LastTransactionDate < d.LapsedDate THEN 8
						ELSE 9 END
				) x
				WHERE inti.CurrentSegmentation > x.NewSegmentation
				GROUP BY inti.BrandID,
						CurrentSegmentation,
						x.NewSegmentation
			-- (893 rows affected) / 00:00:06

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Update Calculate Demotions', @time OUTPUT


			-- Add new Segment
			;WITH SelectedRows AS (
				SELECT 
					inti.CurrentSegmentation,  
					x.NewSegmentation
				FROM #InitialSegmentation inti
				JOIN #JoinDates d
					ON inti.BrandID = d.BrandID
					AND	d.DateRow = (@i + 1)
				CROSS APPLY ( -- x
					SELECT NewSegmentation = CASE
						WHEN inti.LastTransactionDate < d.AcquireDate THEN 7
						WHEN d.AcquireDate <= inti.LastTransactionDate AND inti.LastTransactionDate < d.LapsedDate THEN 8
						ELSE 9 END
				) x
				WHERE inti.CurrentSegmentation <> x.NewSegmentation				
			)
			UPDATE SelectedRows SET
				CurrentSegmentation = NewSegmentation
			-- (4704162 rows affected) / 00:00:40

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Update NewSegmentation ', @time OUTPUT


			-- Delete Customers who are Acquire
			DELETE FROM #InitialSegmentation
			WHERE	CurrentSegmentation = 7
			-- (1813161 rows affected) / 00:00:10

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Delete Acquire', @time OUTPUT


			-- Insert the Acquire Customers who have shopped
			DROP INDEX cix_BrandID_CINID ON #InitialSegmentation 
			INSERT INTO #InitialSegmentation
				SELECT	BrandID,
						CINID,
						LastTransactionDate,
						9 AS CurrentSegmentation,
						0 AS NewSegmentation
				FROM	#CycleLastTranDate td
				WHERE	NOT EXISTS
					(	SELECT 1
						FROM	#InitialSegmentation inti
						WHERE	td.BrandID = inti.BrandID
							AND	td.CINID = inti.CINID)

			CREATE CLUSTERED INDEX cix_BrandID_CINID ON #InitialSegmentation (BrandID,CINID)
			-- (9,610,361 rows affected) / 00:00:17

			EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Insert Additions ', @time OUTPUT



		END -- IF @i < 14 -- ########################################## BLOCK END
			

		SET @i = @i + 1

	END -- WHILE @i <= 1  -- ######################################################################################## LOOP END

	EXEC Prototype.oo_TimerMessage 'ROCEFT - NaturalSalesByCycle -- Script End', @time OUTPUT

	-- Save The New Run Output's
	IF @Bespoke = 1
		BEGIN
			SELECT	a.BrandID,
					a.DateRow AS CycleID,
					d.Seasonality_CycleID AS Seasonality_CycleID,
					a.Segment,
					CASE
					  WHEN a.Segment = 7 THEN @TotalCustomers - COALESCE(e.LapsedShopper,0)
					  ELSE b.Population
					END AS SegmentSize,
					a.Shoppers AS Promoted,
					c.Demotion AS Demoted,
					0 AS OnOffer,
					a.Sales,
					a.OnlineSales,
					a.Transactions,
					a.OnlineTransactions,
					a.Shoppers AS Spenders,
					a.OnlineShoppers AS OnlineSpenders,
					1.0*c.Demotion/NULLIF(b.Population,0) AS DecayRate,
					1.0*a.Shoppers/NULLIF(b.Population,0) AS PromotionRate,
					0 AS OnOfferRate
			FROM	#WorkingDates d
			JOIN	#SegmentOutput a
				ON	a.DateRow = d.DateRow
			LEFT JOIN #SegmentSize b
				ON	a.DateRow = b.DateRow
				AND	a.BrandID = b.BrandID
				AND	a.Segment = b.Segment
			LEFT JOIN #SegmentDemotions c
				ON	a.DateRow = c.DateRow
				AND	a.BrandID = c.BrandID
				AND	a.Segment = c.CurrentSegmentation
			LEFT JOIN
				(	SELECT	DateRow,
							BrandID,
							SUM(Population) AS LapsedShopper
					FROM	#SegmentSize
					GROUP BY DateRow,
							BrandID
				) e
				ON	a.DateRow = e.DateRow
				AND	a.BrandID = e.BrandID
			ORDER BY 1,2,4


			-- Print out distribution
			DECLARE @MaxDateRow INT =  ( SELECT	MAX(DateRow) FROM #WorkingDates )

			SELECT	Segment,
					Population,
					1.0 * Population / NULLIF(@TotalCustomers,0) AS Distribution
			FROM  (
					SELECT	Segment,
							s.Population
					FROM	#SegmentSize s
					WHERE	DateRow = @MaxDateRow
					UNION
					SELECT	7 AS Segment,
							@TotalCustomers - SUM(Population) AS Population
					FROM	#SegmentSize
					WHERE	DateRow = @MaxDateRow
				  ) a
			ORDER BY 1
		END
	ELSE
		BEGIN

			-- Clean up the storage table
			IF @BrandList IS NULL
				BEGIN
					TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles_MyReward
				END
			ELSE
				BEGIN
					DELETE FROM Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles_MyReward
					WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
				END

			-- Insert the output
			INSERT INTO Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles_MyReward
				SELECT	a.BrandID,
						a.DateRow AS CycleID,
						d.Seasonality_CycleID AS Seasonality_CycleID,
						a.Segment,
						CASE
						  WHEN a.Segment = 7 THEN @TotalCustomers - COALESCE(e.LapsedShopper,0)
						  ELSE b.Population
						END AS SegmentSize,
						a.Shoppers AS Promoted,
						c.Demotion AS Demoted,
						0 AS OnOffer,
						a.Sales,
						a.OnlineSales,
						a.Transactions,
						a.OnlineTransactions,
						a.Shoppers AS Spenders,
						a.OnlineShoppers AS OnlineSpenders,
						1.0*c.Demotion/NULLIF(b.Population,0) AS DecayRate,
						1.0*a.Shoppers/NULLIF(b.Population,0) AS PromotionRate,
						0 AS OnOfferRate
				FROM	#WorkingDates d
				JOIN	#SegmentOutput a
					ON	a.DateRow = d.DateRow
				LEFT JOIN #SegmentSize b
					ON	a.DateRow = b.DateRow
					AND	a.BrandID = b.BrandID
					AND	a.Segment = b.Segment
				LEFT JOIN #SegmentDemotions c
					ON	a.DateRow = c.DateRow
					AND	a.BrandID = c.BrandID
					AND	a.Segment = c.CurrentSegmentation
				LEFT JOIN
					(	SELECT	DateRow,
								BrandID,
								SUM(Population) AS LapsedShopper
						FROM	#SegmentSize
						GROUP BY DateRow,
								BrandID
					) e
					ON	a.DateRow = e.DateRow
					AND	a.BrandID = e.BrandID
				ORDER BY 1,2,4
		END
END
select top 10 *
from 
Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles_MyReward