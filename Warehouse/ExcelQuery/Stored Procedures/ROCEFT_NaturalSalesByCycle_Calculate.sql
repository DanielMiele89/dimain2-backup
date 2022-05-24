-- =============================================
-- Author:		<Shaun Hide, Hayden Reid, Zoe Taylor>
-- Create date: <28/04/2017>
/* Purpose:
   - Find SPC, TPC & RR by Segment for the last 14 periods
   - Determine the churn from shoppers from Segment to Segment between periods

   Version History:
   v1.0 - Launched and Optimized
*/
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_NaturalSalesByCycle_Calculate]
	(
		@BrandList VARCHAR(500)
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Declare @time DATETIME
	Declare @msg VARCHAR(100)

	SELECT @msg = 'Natural Sales Table Calculation - Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	----------------------------------------------------------------------------------------------
	-- Brand Selection - Determine the Brand List

	IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
	CREATE TABLE #Brand
		(
			BrandID INT NOT NULL PRIMARY KEY
			,BrandName VARCHAR(50)
			,RowNo INT
		)

	IF @BrandList IS NULL
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

			TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles 
		END
	ELSE
		BEGIN
			INSERT INTO #Brand
				SELECT	BrandID
						,BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0


			DELETE FROM Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles WHERE CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	----------------------------------------------------------------------------------------------
	-- Fixed Base - Find a random 1.5m MyRewards Customers

	IF OBJECT_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	SELECT	TOP 1500000 *
	INTO	#MyRewardsBase
	FROM	(
				SELECT	DISTINCT CINID, CompositeID
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
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX cix_CINID ON #MyRewardsBase(CINID)
	CREATE NONCLUSTERED INDEX nix_CINID ON #MyRewardsBase(CompositeID)

	---------------------------------------------------------------------------------------------
	-- Dates - Generate a Dates Table (Aligns with the other Dates Table)
	
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
					,CAST('2015-04-02' AS DATE) AS CycleStart
					,CAST('2015-04-29' AS DATE) AS CycleEnd
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

	------------------------------------------
	/*
		Subset date table to achieve the following:
		- Allow for a lag in transactions
		- Find the most recent data
	*/
	------------------------------------------

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
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)

	--SELECT * From #WorkingDates

	SELECT @msg = 'Natural Sales Table - Loop Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	DECLARE @BrandID INT, @RowNo INT, @Acquire INT, @Lapsed INT

	SET @RowNo=1
	WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Brand)
		BEGIN
			------------------------------------------
			-- Current Brand: BrandID
			SET @BrandID = (SELECT BrandID FROM	#Brand WHERE RowNo = @RowNo)

			SELECT @msg = 'Running RowNo' + cast(@RowNo as varchar(10)) + ' which is BrandID ' + cast(@BrandID as varchar(10))
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			
			------------------------------------------
			-- Current Brand: ConsumerCombinationIDs
			IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
			SELECT	DISTINCT ConsumerCombinationID
			INTO	#CC
			FROM	Warehouse.Relational.ConsumerCombination cc
			WHERE	BrandID = @BrandID
				AND IsUKSpend = 1 -- Remove?

			CREATE CLUSTERED INDEX cix_ConsumerCombinationID ON #CC(ConsumerCombinationID)

			------------------------------------------
			-- Current Brand: Acquire & Lapsed Settings
			IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
			SELECT	DISTINCT br.BrandName
					,br.BrandID
					,COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
					,COALESCE(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
					,br.SectorID
			INTO	#Settings
			FROM	(
						SELECT	DISTINCT BrandID
								,BrandName
								,SectorID
								,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 3 END AS AcquireL0
								,CASE WHEN BrandName in ('Tesco','Asda','Sainsburys','Morrisons') THEN 1 END AS LapserL0
						FROM	Warehouse.Relational.Brand
					) br
			LEFT JOIN	Warehouse.Relational.Partner p on p.BrandID = br.BrandID
			LEFT JOIN	Warehouse.Relational.MRF_ShopperSegmentDetails mrf on mrf.PartnerID = p.PartnerID
			LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on br.BrandID = blk.BrandID
			LEFT JOIN	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on br.SectorID = lk.SectorID
			WHERE		COALESCE(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) IS NOT NULL
					AND br.BrandID = @BrandID

			SET @Lapsed = (SELECT MIN(LapserL) FROM #Settings)
			SET @Acquire = (SELECT MIN(AcquireL) FROM #Settings)

			------------------------------------------
			-- Current Brand: Date Table

			IF OBJECT_ID('tempdb..#JoinDates') IS NOT NULL DROP TABLE #JoinDates
			SELECT	ID
					,CAST(DATEADD(MONTH,-@Acquire,DATEADD(DAY,-1,CycleStart)) AS DATE) AS AcquireDate
					,CAST(DATEADD(MONTH,-@Lapsed,DATEADD(DAY,-1,CycleStart)) AS DATE) AS LapsedDate
					,CAST(DATEADD(DAY,-1,CycleStart) AS DATE) AS MaxDate
					,CycleStart
					,CycleEnd
					,Seasonality_CycleID
					,DateRow
			INTO	#JoinDates
			FROM	#WorkingDates

			CREATE CLUSTERED INDEX cix_ID ON #JoinDates(ID)
			CREATE NONCLUSTERED INDEX nix_AcquireD ON #JoinDates(AcquireDate)
			CREATE NONCLUSTERED INDEX nix_LapsedD ON #JoinDates(LapsedDate)
			CREATE NONCLUSTERED INDEX nix_MaxD ON #JoinDates(MaxDate)

			------------------------------------------------------------------------------------
			-- Transactions: Find ALL relevant transaction details

			SELECT @msg = 'Finding Transactions'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			DECLARE @MinTranDate DATE = (SELECT MIN(AcquireDate) FROM #JoinDates)
			DECLARE @MaxTranDate DATE = (SELECT MAX(CycleEnd) FROM #JoinDates)

			IF OBJECT_ID('tempdb..#CINTrans') IS NOT NULL DROP TABLE #CINTrans
			SELECT	ct.CINID
					,ct.Amount
					,ct.IsOnline
					,ct.TranDate
			INTO	#CINTrans
			FROM	Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)
			JOIN	#CC cc
				ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
			JOIN	#MyRewardsBase mrb
				ON	mrb.CINID = ct.CINID
			 WHERE  ct.TranDate BETWEEN @MinTranDate and @MaxTranDate
				AND 0 < ct.Amount

			 CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #CinTrans (TranDate)
			 CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #CinTrans (TranDate) INCLUDE (CINID)

			------------------------------------------------------------------------------------
			-- OnOffer : Find ALL CINID / ID Interactions

			SELECT @msg = 'Finding OnOffer'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#OfferList') IS NOT NULL DROP TABLE #OfferList
			SELECT	d.ID
					,IronOfferID
			INTO	#OfferList
			FROM	Warehouse.Relational.IronOffer io
			JOIN	Warehouse.Relational.Partner p 
				ON p.PartnerID = io.PartnerID
			JOIN #WorkingDates d
				ON (
						io.StartDate <= d.CycleEnd
						AND (d.CycleStart <= io.EndDate OR io.EndDate IS NULL)
					)
			 WHERE p.BrandID = @BrandID

			 CREATE CLUSTERED INDEX CIX_OfferList_IronOffer ON #OfferList (ID, IronOfferID)

			IF OBJECT_ID('Tempdb..#OnOffer') IS NOT NULL DROP TABLE #OnOffer
			SELECT	d.ID
					,mrb.CINID
			INTO	#OnOffer
			FROM	#OfferList ol
			JOIN	#WorkingDates d
				ON d.ID = ol.ID
			JOIN	Warehouse.Relational.IronOfferMember iom
				ON	iom.IronOfferID = ol.IronOfferID
				AND	(
						(iom.StartDate <= d.CycleEnd OR iom.StartDate IS NULL)
						AND (d.CycleStart <= iom.EndDate OR iom.EndDate IS NULL)
					)		
			JOIN #MyRewardsBase mrb
				ON mrb.CompositeID = iom.CompositeID
			GROUP BY d.ID
					,mrb.CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #OnOffer(ID,CINID)

			------------------------------------------------------------------------------------
			-- Assignments: Identify Lapsers And Shoppers
			 
			SELECT @msg = 'Find Lapsers'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#PotentialLapsed') IS NOT NULL DROP TABLE #PotentialLapsed
			SELECT	DISTINCT d.ID
					,mrb.CINID
			INTO	#PotentialLapsed
			FROM	#CINTrans ct WITH (NOLOCK)
			JOIN	#JoinDates d ON d.AcquireDate <= ct.TranDate AND ct.TranDate < d.LapsedDate
			JOIN	#MyRewardsBase mrb 
				ON	mrb.CINID = ct.CINID
			
			CREATE CLUSTERED INDEX cix_ComboID ON #PotentialLapsed(ID,CINID)

			SELECT @msg = 'Find Shoppers'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#PotentialShopper') IS NOT NULL DROP TABLE #PotentialShopper
			SELECT	DISTINCT d.ID
					,mrb.CINID
			INTO	#PotentialShopper
			FROM	#CINTrans ct WITH (NOLOCK)
			JOIN	#JoinDates d ON d.LapsedDate <= ct.TranDate AND ct.TranDate <= d.MaxDate
			JOIN	#MyRewardsBase mrb
				ON	mrb.CINID = ct.CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #PotentialShopper(ID,CINID)

			------------------------------------------
			-- Future Period: Metrics

			SELECT @msg = 'Future Metrics'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#FutureSpend') IS NOT NULL DROP TABLE #FutureSpend
			SELECT	d.ID
					,mrb.CINID
					,SUM(ct.Amount) as Sales
					,SUM(CASE WHEN  ct.IsOnline = 1 THEN ct.Amount ELSE NULL END) AS OnlineSales
					,COUNT(1) AS Trans
			INTO	#FutureSpend
			FROM	#CINTrans ct WITH (NOLOCK)
			JOIN	#JoinDates d ON d.CycleStart <= ct.TranDate AND ct.TranDate <= d.CycleEnd
			JOIN	#MyRewardsBase mrb
				ON	mrb.CINID = ct.CINID
			GROUP BY d.ID
					,mrb.CINID

			CREATE CLUSTERED INDEX cix_ComboID ON #FutureSpend(ID,CINID)
			
			------------------------------------------
			-- Assignments: CINID by ID

			SELECT @msg = 'Assignment - CINID by ID'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#Shoppers') IS NOT NULL DROP TABLE #Shoppers
			SELECT		DISTINCT a.ID
						,a.CINID
			INTO		#Shoppers
			FROM		#PotentialShopper a

			CREATE CLUSTERED INDEX cix_ComboID ON #Shoppers(ID,CINID)

			IF OBJECT_ID('tempdb..#Lapsers') IS NOT NULL DROP TABLE #Lapsers
			SELECT		DISTINCT ID
						,CINID
			INTO		#Lapsers
			FROM		#PotentialLapsed a
			WHERE		NOT EXISTS	( SELECT 1
									  FROM	 #Shoppers c
									  WHERE	 a.ID = c.ID
										AND	 a.CINID = c.CINID)

			CREATE CLUSTERED INDEX cix_ComboID ON #Lapsers(ID,CINID)

			------------------------------------------
			-- Assignments: Churn

			SELECT @msg = 'Assignment - Churn'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#LapsedAcquire') IS NOT NULL DROP TABLE #LapsedAcquire
			SELECT		ID
						,COUNT(CINID) AS L_A
			INTO		#LapsedAcquire
			FROM		#Lapsers a
			WHERE		NOT EXISTS ( SELECT	1
									 FROM	#Lapsers b
									 WHERE	a.ID+1 = b.ID
									   AND	a.CINID = b.CINID )
					AND NOT EXISTS ( SELECT	1
									 FROM	#Shoppers c
									 WHERE	a.ID+1 = c.ID
									   AND	a.CINID = c.CINID )
			GROUP BY	ID
			ORDER BY	ID

			IF OBJECT_ID('tempdb..#ShopperLapsed') IS NOT NULL DROP TABLE #ShopperLapsed
			SELECT		a.ID
						,COUNT(a.CINID) AS S_L
			INTO		#ShopperLapsed
			FROM		#Shoppers a
			WHERE		EXISTS ( SELECT	1
								 FROM	#Lapsers b
								 WHERE	a.ID+1 = b.ID
									AND	a.CINID = b.CINID )
			GROUP BY	ID

			------------------------------------------------------------------------------------
			-- Output: Table Preparation

			SELECT @msg = 'Output - Table Preparation'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			IF OBJECT_ID('tempdb..#SpendBySegment') IS NOT NULL DROP TABLE #SpendBySegment
			SELECT	*
			INTO	#SpendBySegment
			FROM	(							
						SELECT		s.ID
									,'Shopper' AS Segment
									,SUM(Sales) AS Sales
									,SUM(OnlineSales) AS OnlineSales
									,SUM(Trans) AS Transactions
									,COUNT(DISTINCT fs.CINID) AS Spenders
						FROM		#Shoppers s
						JOIN		#FutureSpend fs
								ON  s.ID = fs.ID
								AND s.CINID = fs.CINID
						GROUP BY	s.ID
						UNION
						SELECT		l.ID
									,'Lapsed' AS Segment
									,SUM(Sales) AS Sales
									,SUM(OnlineSales) AS OnlineSales
									,SUM(Trans) AS Transactions
									,COUNT(DISTINCT fs.CINID) AS Spenders
						FROM		#Lapsers l
						JOIN		#FutureSpend fs
								ON	l.ID = fs.ID
								AND l.CINID = fs.CINID
						GROUP BY	l.ID
						UNION
						SELECT		fs.ID
									,'Acquire' AS Segment
									,SUM(Sales) AS Sales
									,SUM(OnlineSales) AS OnlineSales
									,SUM(Trans) AS Transactions
									,COUNT(DISTINCT fs.CINID) AS Spenders
						FROM		#FutureSpend fs
						WHERE		NOT EXISTS ( SELECT	1
													FROM	#Lapsers b
													WHERE	fs.ID = b.ID
													AND	fs.CINID = b.CINID )
								AND NOT EXISTS ( SELECT	1
													FROM	#Shoppers c
													WHERE	fs.ID = c.ID
													AND	fs.CINID = c.CINID )
						GROUP BY	fs.ID
					) a
			
			CREATE CLUSTERED INDEX cix_ComboID ON #SpendBySegment(ID,Segment)

			IF OBJECT_ID('tempdb..#SegmentSizes') IS NOT NULL DROP TABLE #SegmentSizes
			SELECT	*
			INTO	#SegmentSizes
			FROM	(
						SELECT	ID
								,'Shopper' AS Segment
								,COUNT(CINID) AS SegSize
						FROM	#Shoppers
						GROUP BY ID
						UNION
						SELECT	ID
								,'Lapsed' AS Segment
								,COUNT(CINID) AS SegSize
						FROM	#Lapsers
						GROUP BY ID
						UNION
						SELECT  ID
								,'Acquire' AS Segment
								,1500000 - SegSize AS SegSize
						FROM (	SELECT	ID
										,SUM(SegSize) AS SegSize
								FROM (
										SELECT	ID
												,COUNT(CINID) AS SegSize
										FROM	#Shoppers
										GROUP BY ID
										UNION
										SELECT	ID
												,COUNT(CINID) AS SegSize
										FROM	#Lapsers
										GROUP BY ID
										) a
								GROUP BY ID
								) a
						) seg

			CREATE CLUSTERED INDEX cix_ComboID ON #SegmentSizes(ID,Segment)

			IF OBJECT_ID('tempdb..#DecayRates') IS NOT NULL DROP TABLE #DecayRates
			SELECT	*
			INTO	#DecayRates
			FROM	(
						SELECT	ID
								,'Shopper' AS Segment
								,S_L AS DecayRate
						FROM	#ShopperLapsed
						UNION
						SELECT	ID
								,'Lapsed' AS Segment
								,L_A AS DecayRate
						FROM	#LapsedAcquire
					) a

			CREATE CLUSTERED INDEX cix_ComboID ON #DecayRates(ID,Segment)

			IF OBJECT_ID('tempdb..#ShoppersOnOffer') IS NOT NULL DROP TABLE #ShoppersOnOffer
			SELECT	*
			INTO	#ShoppersOnOffer
			FROM	(
						SELECT	oo.ID
								,'Shopper' AS Segment
								,COUNT(oo.CINID) AS OnOffer
						FROM	#OnOffer oo
						JOIN	#Shoppers s
							ON	s.ID = oo.ID
							AND s.CINID = oo.CINID
						GROUP BY oo.ID
						UNION
						SELECT	oo.ID
								,'Lapsed' AS Segment
								,COUNT(oo.CINID) AS OnOffer
						FROM	#OnOffer oo
						JOIN	#Lapsers l
							ON	l.ID = oo.ID
							AND l.CINID = oo.CINID
						GROUP BY oo.ID
						UNION
						SELECT		oo.ID
									,'Acquire' AS Segment
									,COUNT(oo.CINID) AS OnOffer
						FROM		#OnOffer oo
						WHERE		NOT EXISTS ( SELECT	1
												 FROM	#Lapsers b
												 WHERE	oo.ID = b.ID
													AND	oo.CINID = b.CINID )
								AND NOT EXISTS ( SELECT	1
												 FROM	#Shoppers c
												 WHERE	oo.ID = c.ID
													AND	oo.CINID = c.CINID )
						GROUP BY oo.ID
					) a

			CREATE CLUSTERED INDEX cix_ComboID ON #ShoppersOnOffer(ID,Segment)

			------------------------------------------------------------------------------------
			-- Output : Table Insertion

			SELECT @msg = 'Output - Insertion'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
			
			INSERT INTO Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles
				SELECT		@BrandID AS BrandID
							,DateRow AS CycleID
							,Seasonality_CycleID
							,CASE
								WHEN seg.Segment = 'Acquire' THEN 7
								WHEN seg.Segment = 'Lapsed' THEN 8
								WHEN seg.Segment = 'Shopper' THEN 9
							END AS Segment
							,SegSize AS SegmentSize
							,sp.Spenders AS Promoted
							,ISNULL(dec.DecayRate,0) AS Demoted
							,ISNULL(soo.OnOffer,0) AS OnOffer
							,ISNULL(sp.Sales,0) AS Sales
							,ISNULL(sp.OnlineSales,0) AS OnlineSales
							,ISNULL(sp.Transactions,0) AS Transactions
							,ISNULL(sp.Spenders,0) AS Spenders
							,COALESCE(1.0*dec.DecayRate/NULLIF(SegSize,0),0) AS DecayRate
							,COALESCE(1.0*sp.Spenders/NULLIF(SegSize,0),0) AS PromotionRate
							,COALESCE(1.0*soo.OnOffer/NULLIF(SegSize,0),0) AS OnOfferRate
				FROM		#JoinDates d
				LEFT JOIN	#SegmentSizes seg
						ON	d.ID = seg.ID
				LEFT JOIN	#SpendBySegment sp
						ON  d.ID = sp.ID
						AND seg.Segment = sp.Segment
				LEFT JOIN	#DecayRates dec
						ON	d.ID = dec.ID
						AND seg.Segment = dec.Segment
				LEFT JOIN	#ShoppersOnOffer soo
						ON	d.ID = soo.ID
						AND seg.Segment = soo.Segment
				ORDER BY 1,2,4

			
			OPTION (RECOMPILE)

			SET @RowNo = @RowNo + 1
			
			SELECT @msg = 'Natural Sales Table - Loop End'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
		END

	SELECT @msg = 'Natural Sales Table - Procedure End'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	--IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles
	--CREATE TABLE Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles
	--	(
	--		BrandID INT NOT NULL
	--		,CycleID INT NOT NULL
	--		,Seasonality_CycleID INT NOT NULL
	--		,Segment INT NOT NULL
	--		,SegmentSize INT
	--		,Promoted INT
	--		,Demoted INT
	--		,OnOffer INT
	--		,Sales	MONEY
	--		,OnlineSales MONEY
	--		,Transactions INT
	--		,Spenders INT
	--		,DecayRate FLOAT
	--		,PromotionRate FLOAT
	--		,OnOfferRate FLOAT
	--		,PRIMARY KEY (BrandID, CycleID, Seasonality_CycleID, Segment)
	--	)	
END