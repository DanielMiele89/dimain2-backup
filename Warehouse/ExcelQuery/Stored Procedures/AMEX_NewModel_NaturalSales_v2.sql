-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[AMEX_NewModel_NaturalSales_v2]
	-- Add the parameters for the stored procedure here

@BrandList VARCHAR(500)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
DECLARE @time DATETIME
	DECLARE @msg VARCHAR(100)
	

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
	IF @BrandList IS NOT NULL		
		Begin
				INSERT INTO #Brand
				SELECT	A.BrandID
						,A.BrandName
						,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
				FROM	
						(Select Distinct BrandId, BrandName FROM Warehouse.Relational.Brand
						Where CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0) A
				DELETE 
				FROM Warehouse.ExcelQuery.AmexModelNaturalSales 
				Where CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END
	IF @BrandList IS NULL 
		Begin
							TRUNCATE TABLE Warehouse.ExcelQuery.AmexModelNaturalSales
							INSERT INTO #Brand
							SELECT	A.BrandID
									,A.BrandName
									,ROW_NUMBER() OVER (ORDER BY BrandID) RowNo
							FROM	Warehouse.Prototype.AMEX_BrandList A
		END

	-- Select * from #Brand
	----------------------------------------------------------------------------------------------
	-- Fixed Base - Find a random 1.5m MyRewards Customers

	IF OBJECT_ID('tempdb..#MyRewardsBase') IS NOT NULL DROP TABLE #MyRewardsBase
	SELECT	TOP 1500000 *
	INTO	#MyRewardsBase
	FROM	(
				SELECT				DISTINCT CINID
				FROM				Warehouse.Relational.Customer c 
				LEFT OUTER JOIN		(SELECT	DISTINCT FanID
									 FROM	Warehouse.Relational.Customer_RBSGSegments
									 WHERE	StartDate <= GETDATE()
										AND (EndDate IS NULL OR EndDate > GETDATE())
										AND CustomerSegment = 'V') priv
								ON	priv.FanID = c.FanID
				LEFT OUTER JOIN		Warehouse.Relational.CAMEO cam  WITH (NOLOCK)
								ON	c.PostCode = cam.Postcode
				LEFT OUTER JOIN		Warehouse.Relational.CINList cl
								ON	c.SourceUID = cl.CIN
				WHERE			(	priv.FanID IS NOT NULL
								OR  cam.CAMEO_CODE_GROUP IN ('01','02','03','04'))
								AND cl.CINID IS NOT NULL
								AND NOT EXISTS	(
													SELECT	*
													FROM	Warehouse.Staging.Customer_DuplicateSourceUID dup
													WHERE	EndDate IS NULL
														AND c.SourceUID = dup.SourceUID
												)
				) a
	ORDER BY NEWID()

	CREATE CLUSTERED INDEX cix_CINID ON #MyRewardsBase(CINID)
	
	---------------------------------------------------------------------------------------------
	-- Dates - Generate a Dates Table (Aligns with the other Dates Table)

	------------------------------------------
	/*
		Subset date table to achieve the following:
		- Allow for a lag in transactions
		- Find the most recent data
	*/
	------------------------------------------

	IF OBJECT_ID('tempdb..#WorkingDates') IS NOT NULL DROP TABLE #WorkingDates
	SELECT	*
			--,ROW_NUMBER() OVER (ORDER BY ID ASC) AS DateRow
	INTO	#WorkingDates
	FROM	Warehouse.ExcelQuery.Amex_NewModel_Dates

	CREATE CLUSTERED INDEX cix_DateRow ON #WorkingDates(DateRow)
	CREATE NONCLUSTERED INDEX nix_CycleStart ON #WorkingDates(CycleStart)
	CREATE NONCLUSTERED INDEX nix_CycleEnd ON #WorkingDates(CycleEnd)

	-- SELECT * FROM #WorkingDates

----------------------------------------------------------------------------------------------
-- Start the LOOP!!!!!!!!!


	SELECT @msg = 'Natural Sales Table - Loop Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	DECLARE @BrandID INT, @RowNo INT, @Acquire INT, @Lapsed INT

	SET @RowNo=1
	WHILE @RowNo <= (SELECT MAX(RowNo) FROM #Brand)
		BEGIN
			---------------------------------------------------------------------------------------------
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

			SET @Lapsed = 3
			SET @Acquire = 6

			------------------------------------------
			-- Current Brand: Date Table

			IF OBJECT_ID('tempdb..#JoinDates') IS NOT NULL DROP TABLE #JoinDates
			SELECT	DateRow AS ID
					,CAST(DATEADD(MONTH,-@Acquire,DATEADD(DAY,-1,CycleStart)) AS DATE) AS AcquireDate
					,CAST(DATEADD(MONTH,-@Lapsed,DATEADD(DAY,-1,CycleStart)) AS DATE) AS LapsedDate
					,CAST(DATEADD(DAY,-1,CycleStart) AS DATE) AS MaxDate
					,CycleStart
					,CycleEnd
					,DateRow
			INTO	#JoinDates
			FROM	#WorkingDates

			CREATE CLUSTERED INDEX cix_ID ON #JoinDates(ID)
			CREATE NONCLUSTERED INDEX nix_AcquireD ON #JoinDates(AcquireDate)
			CREATE NONCLUSTERED INDEX nix_LapsedD ON #JoinDates(LapsedDate)
			CREATE NONCLUSTERED INDEX nix_MaxD ON #JoinDates(MaxDate)

			-- SELECT * FROM #JoinDates
			
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
			FROM	#CC cc				
			INNER LOOP JOIN Warehouse.Relational.ConsumerTransaction ct WITH (NOLOCK)	
				ON	cc.ConsumerCombinationID = ct.ConsumerCombinationID
			JOIN	#MyRewardsBase mrb
				ON	mrb.CINID = ct.CINID
			WHERE  ct.TranDate BETWEEN @MinTranDate and @MaxTranDate
				AND 0 < ct.Amount

			 CREATE CLUSTERED INDEX CIX_CinTrans_Main ON #CinTrans (TranDate)
			 CREATE NONCLUSTERED INDEX NIX_CinTrans_Shh ON #CinTrans (TranDate) INCLUDE (CINID)

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
									  WHERE	 a.ID = c.ID AND
									  	 a.CINID = c.CINID)

			CREATE CLUSTERED INDEX cix_ComboID ON #Lapsers(ID,CINID)

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


			------------------------------------------------------------------------------------
			-- Output : Table Insertion

			SELECT @msg = 'Output - Insertion'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

			--IF OBJECT_ID('Sandbox.Satty.Amex_MyRewards_Customers') IS NOT NULL DROP TABLE Sandbox.Satty.Amex_MyRewards_Customers
			--Truncate TABLE Warehouse.ExcelQuery.AmexModelNatualSales
			--INSERT INTO Sandbox.Satty.AmexModelNatualSales
			Insert Into Warehouse.ExcelQuery.AmexModelNaturalSales
				SELECT		@BrandID AS BrandID
							,DateRow AS CycleID
							,D.CycleStart
							,D.CycleEnd
							,seg.Segment
							,SegSize AS SegmentSize
							,ISNULL(sp.Sales,0) AS Sales
							,ISNULL(sp.OnlineSales,0) AS OnlineSales
							,ISNULL(sp.Transactions,0) AS Transactions
							,ISNULL(sp.Spenders,0) AS Spenders
							,sp.Spenders/(1.0*SegSize) AS RR
							,sp.Sales/sp.Spenders AS SPS
							,sp.Sales/SegSize AS SPC
							,sp.Transactions/(1.0*SegSize) AS TPC
				FROM		#JoinDates d
				LEFT JOIN	#SegmentSizes seg
						ON	d.ID = seg.ID
				LEFT JOIN	#SpendBySegment sp
						ON  d.ID = sp.ID
						AND seg.Segment = sp.Segment
				ORDER BY 1,2,4

			SET @RowNo = @RowNo + 1
			
			SELECT @msg = 'Natural Sales Table - Loop End'
			EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
	END
END
