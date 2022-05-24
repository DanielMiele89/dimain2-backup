-- =============================================
-- Author:		<Shaun H>
-- Create date: <22/06/2017>
-- Description:	<nFI Spend History by Publisher by Retailer by Segment>
/* Change Log:
	- 7th July SH Added in ClubID to all tables
	- 22nd August SH Adjusted Weightings - This still needs to be looked at
*/
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_nFISpendHistory_Calculate_v4]
AS
BEGIN
	SET NOCOUNT ON;



	INSERT INTO Warehouse.InsightArchive.ROCEFT_PubScaling_Segment_Archive
		SELECT		Getdate() as BackupTime,
					*
		FROM		Warehouse.ExcelQuery.ROCEFT_PubScaling_Segment
	
	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_PubScaling_Segment


	INSERT INTO Warehouse.InsightArchive.ROCEFT_PubScaling_Archive
		SELECT		Getdate() as BackupTime,
					*
		FROM		Warehouse.ExcelQuery.ROCEFT_PubScaling
	
	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_PubScaling

	SET DATEFIRST 1

	DECLARE @CurrentCycle INT
	DECLARE @CycleIDRef INT
	DECLARE @SeasonalityCycleID INT

	SET @CurrentCycle =		(
								SELECT	ID
								FROM	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
								WHERE	CAST(DATEADD(DAY,-7,GETDATE()) AS DATE) BETWEEN CycleStart AND CycleEnd
							)
	SET @CycleIDRef = @CurrentCycle - 1
	SET @SeasonalityCycleID = (
								SELECT	Seasonality_CycleID
								FROM	Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
								WHERE	ID = @CycleIDRef
							  )

	IF OBJECT_ID('tempdb..#DateRanges') IS NOT NULL DROP TABLE #DateRanges
	SELECT		CAST(GETDATE() AS DATE) as RunDate
				,CycleStart as StartFourWeek
				,CycleEnd as EndFourWeek
				,Seasonality_CycleID
	INTO		#DateRanges
	FROM		Warehouse.ExcelQuery.ROCEFT_ROC_Cycle_Calendar_Extended
	WHERE		ID = @CycleIDRef

	DECLARE		@EvalPeriod_Start		DATE =	(SELECT StartFourWeek FROM #DateRanges)
	DECLARE		@EvalPeriod_End			DATE =	(SELECT EndFourWeek FROM #DateRanges)
	DECLARE		@HistoricPeriod_End		DATE =	(SELECT DATEADD(DAY,-1,@EvalPeriod_Start))
	DECLARE		@HistoricPeriod_3Months	DATE =	(SELECT DATEADD(DAY,1,DATEADD(MONTH,-3,@HistoricPeriod_End)))
	DECLARE		@RunDate				DATE =	(SELECT RunDate FROM #DateRanges)

	--  Create list of nFI Customers with an active card in the segmentation period
	IF OBJECT_ID('tempdb..#nFICusts') IS NOT NULL DROP TABLE #nFICusts
	SELECT		CASE 
					WHEN c.name = 'Karrot' THEN 'Airtime Rewards'
					WHEN c.name = 'Avios Collinson Group' THEN 'Collinson - Avios'
					WHEN c.name = 'British Airways Collinson Group' THEN 'Collinson - BAA'
					WHEN c.name = 'VAA Collinson Group' THEN 'Collinson - Virgin'
					WHEN c.name = 'MBNA Collinson Group' THEN 'Collinson - MBNA'
					WHEN c.name = 'UA Collinson Group' THEN 'Collinson - UA'
					WHEN c.name = 'Gobsmack More Than' THEN 'Gobsmack - More Than'
					WHEN  r4g.CompositeID IS NOT NULL THEN 'R4G'
					ELSE c.name 
				END AS ClubName
				,ClubID
				,f.ID
				,f.CompositeID
				,p.ID as PanID
				,r4g.CompositeID as R4G_Flag
	INTO		#nFICusts 
	FROM		SLC_Report.dbo.Fan f WITH (NOLOCK)
	JOIN		SLC_Report.dbo.Pan p WITH (NOLOCK)	ON F.CompositeID = P.CompositeID
	JOIN		SLC_Report.dbo.Club c WITH (NOLOCK)	ON c.ID = f.clubid
	LEFT JOIN	Warehouse.InsightArchive.QuidcoR4GCustomers r4g WITH(NOLOCK) ON f.CompositeID = r4g.CompositeID
	WHERE		p.AdditionDate <= @HistoricPeriod_End 
			AND (p.RemovalDate > @HistoricPeriod_End OR RemovalDate IS NULL)
			AND ClubID NOT IN (132,138)
	GROUP BY	CASE 
					WHEN c.name = 'Karrot' THEN 'Airtime Rewards'
					WHEN c.name = 'Avios Collinson Group' THEN 'Collinson - Avios'
					WHEN c.name = 'British Airways Collinson Group' THEN 'Collinson - BAA'
					WHEN c.name = 'VAA Collinson Group' THEN 'Collinson - Virgin'
					WHEN c.name = 'MBNA Collinson Group' THEN 'Collinson - MBNA'
					WHEN c.name = 'UA Collinson Group' THEN 'Collinson - UA'
					WHEN c.name = 'Gobsmack More Than' THEN 'Gobsmack - More Than'
					WHEN  r4g.CompositeID IS NOT NULL THEN 'R4G'
					ELSE c.name 
				END
				,ClubID
				,f.ID
				,f.CompositeID
				,p.ID
				,r4g.CompositeID

	CREATE CLUSTERED INDEX Idx_PanID ON #nFICusts(PanID)
	CREATE NONCLUSTERED INDEX Idx_CompID ON #nFICusts(CompositeID)

	-- Create List of Publishers
	IF OBJECT_ID('Tempdb..#nFIPubs') IS NOT NULL DROP TABLE #nFIPubs
	SELECT		DISTINCT PublisherID as ClubID
				,PublisherName as ClubName
	INTO		#nFIPubs
	FROM		Warehouse.ExcelQuery.ROCEFT_Publishers 
	WHERE		PublisherName <> 'RBS'	

	--  Get spend data by retailer
	IF OBJECT_ID('tempdb..#Pub_Retailer_FirstLast') IS NOT NULL DROP TABLE #Pub_Retailer_FirstLast
	SELECT		ClubID
				,ClubName
				,pb.BrandID
				,CAST(MIN(TransactionDate) as date) as FirstTrandate
				,CAST(MAX(TransactionDate) as date) as LastTrandate
	INTO		#Pub_Retailer_FirstLast
	FROM		#nFiCusts n
	JOIN		SLC_Report.dbo.Match m  WITH (NOLOCK) ON n.PanID = m.PanID
	JOIN		SLC_Report.dbo.RetailOutlet ro WITH (NOLOCK) ON m.RetailOutletID = ro.ID
	JOIN		SLC_Report.dbo.Partner p WITH (NOLOCK) ON ro.PartnerID = p.ID
	JOIN		Warehouse.Staging.Partners_Vs_Brands pb ON p.ID = pb.PartnerID
	WHERE		m.Status IN (1)				-- Valid transaction status
			AND m.RewardStatus IN (0,1)		-- Valid transaction status    
	GROUP BY	ClubID
				,ClubName
				,pb.BrandID
	ORDER BY	Clubname
				,pb.BrandID

	IF OBJECT_ID('tempdb..#Pub_Retailer_FirstLast_Valid') IS NOT NULL DROP TABLE #Pub_Retailer_FirstLast_Valid
	SELECT	IDENTITY(INT, 1,1) AS RNum
			,a.*
			,b.AcquireL
			,b.LapserL
	INTO	#Pub_Retailer_FirstLast_Valid
	FROM	#Pub_Retailer_FirstLast a
	JOIN	Warehouse.ExcelQuery.ROCEFT_Segment_Lengths b ON a.BrandID = b.BrandID
	WHERE	DATEDIFF(MONTH, FirstTranDate, LastTranDate) >=3
		AND ClubName NOT IN ('NatWest MyRewards','RBS MyRewards')

	--  Create last Spend by Retailer to calculate a customer's shopper segment
	IF OBJECT_ID('tempdb..#nFICusts_Last') IS NOT NULL DROP TABLE #nFICusts_Last
	CREATE TABLE #nFICusts_Last
		(
			ClubID	INT
			,Clubname  VARCHAR(50)
			,BrandID INT
			,CompositeID BIGINT
			,LastTrandate  DATE
		)


	DECLARE @Counter INT = 1
	DECLARE @Max INT = (SELECT MAX(RNum) FROM #Pub_Retailer_FirstLast_Valid)

	WHILE @Counter <= @Max
		BEGIN
				DECLARE @ClubName VARCHAR(50) = (SELECT ClubName FROM #Pub_Retailer_FirstLast_Valid WHERE RNum = @Counter)
				DECLARE @BrandID_a INT = (SELECT BrandID FROM #Pub_Retailer_FirstLast_Valid WHERE RNum = @Counter)
		
				INSERT INTO	#nFICusts_Last
					SELECT		x.ClubID
								,x.Clubname
								,@BrandID_a
								,x.CompositeID
								,LastTrandate	
					FROM		(
									SELECT	DISTINCT ClubID
											,ClubName
											,CompositeID
									FROM	#nFICusts
									WHERE	ClubName = @ClubName
								) x
					LEFT JOIN	(
									SELECT		a.Clubname
												,pb.BrandID
												,CompositeID
												,CAST(MAX(TransactionDate) AS DATE) AS LastTrandate		
									FROM		#nFICusts a
									JOIN		#Pub_Retailer_FirstLast_Valid b ON a.ClubName = b.ClubName 
									JOIN		SLC_Report.dbo.match m WITH (NOLOCK) ON a.PanID = m.PanID 
									Join		Warehouse.Staging.Partners_Vs_Brands pb ON b.BrandID = pb.BrandID
									JOIN		SLC_Report.dbo.RetailOutlet ro WITH (NOLOCK) ON m.RetailOutletID = ro.ID and ro.PartnerID = pb.PartnerID
									WHERE		b.RNum = @Counter
											AND CAST(TransactionDate AS DATE) <= @HistoricPeriod_End
									GROUP BY	a.Clubname
												,pb.BrandID
												,CompositeID
								) y ON x.CompositeID = y.CompositeID 

				SET @Counter = @Counter + 1
		END

	CREATE CLUSTERED INDEX Idx_CompID on #nFICusts_Last(CompositeID)

	--  Calculate Segments for nFI
	IF OBJECT_ID('tempdb..#nFICusts_Segments') IS NOT NULL DROP TABLE #nFICusts_Segments
	SELECT	ClubID
			,ClubName
			,a.BrandID
			,CompositeID
			,LastTranDate
			,CASE
				WHEN LastTranDate IS NULL THEN 'Acquire' 
				WHEN LastTranDate < DATEADD(MONTH,-AcquireL, @HistoricPeriod_End) THEN 'Acquire'
				WHEN LastTranDate < DATEADD(MONTH,-LapserL, @HistoricPeriod_End) THEN 'Lapsed'
				WHEN LastTranDate >= DATEADD(MONTH,-LapserL, @HistoricPeriod_End) THEN 'Shopper'
				ELSE 'Error'
			END AS Shopper_Segment
	INTO	#nFICusts_Segments			
	FROM	#nFICusts_Last a
	JOIN	Warehouse.ExcelQuery.ROCEFT_Segment_Lengths b ON a.BrandID = b.BrandID

	---New Lloyd code----
	IF OBJECT_ID('tempdb..#SegmentSummaries') IS NOT NULL DROP TABLE #SegmentSummaries
	SELECT		ClubID
				,ClubName
				,Shopper_Segment
				,BrandID
				,COUNT(DISTINCT CompositeID) AS cardholders
				,MIN(LastTrandate) AS firsttrandate
				,MAX(LastTrandate) AS lasttrandate
	INTO		#SegmentSummaries
	FROM		#nfiCusts_Segments
	GROUP BY	ClubID
				,ClubName
				,Shopper_Segment
				,BrandID

	--  Create transactional Table for all customers, including customers without a segment (which will default to Acquire)
	IF OBJECT_ID('tempdb..#CustTxns') IS NOT NULL DROP TABLE #CustTxns
	SELECT		a.ClubID
				,a.Clubname
				,b.BrandID
				,CompositeID
				,SUM(Amount) AS Spend
				,COUNT(*) AS Transactions
	INTO		#CustTxns
	FROM		#nFICusts a
	JOIN		#Pub_Retailer_FirstLast_Valid b ON a.ClubName = b.ClubName 
	JOIN		Warehouse.Staging.Partners_Vs_Brands pb ON b.brandid = pb.brandid
	JOIN		SLC_Report.dbo.Match m WITH (NOLOCK) ON a.PanID = m.PanID 
	JOIN		SLC_Report.dbo.RetailOutlet ro WITH (NOLOCK) ON m.RetailOutletID = ro.ID and ro.PartnerID = pb.PartnerID
	WHERE		m.Status IN (1)					-- Valid transaction status
			AND m.RewardStatus IN (0,1)		-- Valid transaction status
			AND 0 < Amount 
			AND CAST(TransactionDate AS DATE) BETWEEN @EvalPeriod_Start AND @EvalPeriod_End
	GROUP BY	a.ClubID
				,a.Clubname
				,b.BrandID
				,CompositeID

	IF OBJECT_ID('tempdb..#IncentivisedSpend') IS NOT NULL DROP TABLE #IncentivisedSpend
	SELECT		a.ClubID
				,a.ClubName
				,a.BrandID
				,CASE
					WHEN Shopper_Segment IS NULL THEN 'Acquire'
					ELSE Shopper_Segment
				END AS ShopperSegment
				,SUM(Spend) AS Spend
				,SUM(Transactions) AS Transactions
				,COUNT(DISTINCT a.CompositeID) as Spenders
	INTO		#IncentivisedSpend
	FROM		#CustTxns a
	LEFT JOIN	#nFICusts_Segments b ON a.CompositeID = b.compositeID AND a.clubname = b.clubname AND a.BrandID = b.brandid
	GROUP BY	a.ClubID
				,a.Clubname
				,a.BrandID
				,CASE
					WHEN Shopper_Segment IS NULL THEN 'Acquire'
					ELSE Shopper_Segment
				 END

	-- Incentivised Spend Summary Tables
	IF OBJECT_ID('Tempdb..#SegmentIncentivisedSpendSummary') IS NOT NULL DROP TABLE #SegmentIncentivisedSpendSummary
	SELECT		ss.ClubID
				,ss.ClubName
				,ss.Shopper_Segment
				,ss.BrandID
				,ss.Cardholders
				,Spenders
				,Spend
				,Transactions
				,COALESCE(Spenders*1.0/NULLIF(ss.Cardholders,0),0) AS RR
				,COALESCE(Spend/NULLIF(ss.Cardholders,0),0) AS SPC
				,COALESCE(Spend/NULLIF(Spenders,0),0) AS SPS
				,COALESCE(Spend/NULLIF(Transactions,0),0) AS ATV
				,COALESCE(Transactions*1.0/NULLIF(Spenders,0),0) AS ATF
				,COALESCE(Transactions*1.0/NULLIF(ss.Cardholders,0),0) AS TPC
	INTO		#SegmentIncentivisedSpendSummary
	FROM		#SegmentSummaries ss
	LEFT JOIN	#IncentivisedSpend a
			ON	a.ClubName = ss.ClubName
			AND a.ShopperSegment = ss.Shopper_Segment
			AND	a.BrandID = ss.BrandID 

	IF OBJECT_ID('tempdb..#UniversalIncentivisedSpendSummary') IS NOT NULL DROP TABLE #UniversalIncentivisedSpendSummary
	SELECT	ClubID
			,ClubName
			,BrandID
			,SUM(Cardholders) AS Cardholders
			,SUM(Spenders) AS Spenders
			,SUM(Spend) AS Spend
			,SUM(Transactions) AS Transactions
			,COALESCE(SUM(Spenders)*1.0/NULLIF(SUM(Cardholders),0),0) AS RR
			,COALESCE(SUM(Spend)/NULLIF(SUM(Cardholders),0),0) AS SPC
			,COALESCE(SUM(Spend)/NULLIF(SUM(Spenders),0),0) AS SPS
			,COALESCE(SUM(Spend)/NULLIF(SUM(Transactions),0),0) AS ATV
			,COALESCE(SUM(Transactions)*1.0/NULLIF(SUM(Spenders),0),0) AS ATF
			,COALESCE(SUM(Transactions)*1.0/NULLIF(SUM(Cardholders),0),0) AS TPC
	INTO	#UniversalIncentivisedSpendSummary
	FROM	#SegmentIncentivisedSpendSummary
	GROUP BY ClubID
			,ClubName
			,BrandID

	-- PUBLISHER SCALING FACTORS
	IF OBJECT_ID('tempdb..#Universal_CoreData') IS NOT NULL DROP TABLE #Universal_CoreData
	SELECT		a.ClubID
				,a.ClubName
				,a.BrandID
				,ISNULL(a.Spenders,0) AS NFI_Spenders
				,ISNULL(b.Spenders,0) AS RBS_Spenders
				,ISNULL(a.RR,0) AS NFI_RR
				,ISNULL(b.RR,0) AS RBS_RR
				,COALESCE(1.0*a.RR/NULLIF(b.RR,0),0) as PubScaling
				,CASE
					WHEN ((a.RR*a.Cardholders) <= 100 OR (b.RR*b.Cardholders <=100) OR (a.RR*a.Cardholders IS NULL) OR (b.RR*b.Cardholders IS NULL)) THEN 1
					ELSE 0
				 END AS LowFlag --- added null to clause
	INTO	#Universal_CoreData
	FROM	#UniversalIncentivisedSpendSummary a
	JOIN	(SELECT BrandID
					 ,SUM(SegmentSize) AS Cardholders
					 ,SUM(Spenders) AS Spenders
					 ,COALESCE(1.0*SUM(Spenders)/NULLIF(SUM(SegmentSize),0),0) AS RR
	         FROM	Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles
			 WHERE	(CycleID <> 1 AND Seasonality_CycleID = @SeasonalityCycleID)
			 GROUP BY BrandID
			) b 
		ON	a.BrandID = b.BrandID

	IF OBJECT_ID('tempdb..#Universal_ToUseScaling') IS NOT NULL DROP TABLE #Universal_ToUseScaling
	SELECT	ClubID
			,ClubName
			,BrandID
	INTO	#Universal_ToUseScaling
	FROM	#Universal_CoreData
	GROUP BY ClubID
			,ClubName
			,BrandID
	HAVING SUM(LowFlag) = 0

	INSERT INTO	Warehouse.ExcelQuery.ROCEFT_PubScaling 
		SELECT	ClubID
				,ClubName
				,AVG(PubScaling) AS RR_Scaling	
		FROM	(
					SELECT		CASE
									WHEN a.ClubName = 'R4G' THEN NULL
									ELSE a.ClubID
								END AS ClubID
								,a.Clubname
								,a.BrandID
								,CASE
									WHEN PubScaling < 0.3 THEN 0.3
									WHEN 3 < PubScaling THEN 3 
									ELSE PubScaling
								 END AS PubScaling
					FROM		#Universal_CoreData a
					INNER JOIN	#Universal_ToUseScaling b
							ON	a.BrandID = b.BrandID
							AND a.ClubName = b.ClubName
				) c 
		GROUP BY ClubID
				,ClubName
		ORDER BY ClubName


	-- PUBLISHER BY SEGMENT SCALING FACTORS
	IF OBJECT_ID('tempdb..#Segment_CoreData') IS NOT NULL DROP TABLE #Segment_CoreData
	SELECT		a.ClubID
				,a.ClubName
				,a.BrandID
				,a.Shopper_Segment
				,ISNULL(a.Spenders,0) AS NFI_Spenders
				,ISNULL(b.Spenders,0) AS RBS_Spenders
				,ISNULL(a.RR,0) AS NFI_RR
				,ISNULL(b.RR,0) AS RBS_RR
				,COALESCE(1.0*a.RR/NULLIF(b.RR,0),0) as PubScaling
				,CASE
					WHEN ((a.RR*a.Cardholders) <= 100 OR (b.RR*b.Cardholders <=100) OR (a.RR*a.Cardholders IS NULL) OR (b.RR*b.Cardholders IS NULL)) THEN 1
					ELSE 0
				 END AS LowFlag --- added null to clause
	INTO	#Segment_CoreData
	FROM	#SegmentIncentivisedSpendSummary a
	JOIN	(SELECT BrandID
					,CASE
						WHEN Segment = 7 THEN 'Acquire'
						WHEN Segment = 8 THEN 'Lapsed'
						WHEN Segment = 9 THEN 'Shopper'
					 END AS Shopper_Segment
					 ,SegmentSize AS Cardholders
					 ,Spenders
					 ,COALESCE(1.0*Spenders/NULLIF(SegmentSize,0),0) AS RR
	         FROM	Warehouse.ExcelQuery.ROCEFT_NaturalSpendCycles
			 WHERE	(CycleID <> 1 AND Seasonality_CycleID = @SeasonalityCycleID)
			) b 
		ON	a.Shopper_Segment = b.Shopper_Segment
		AND a.BrandID = b.BrandID

	IF OBJECT_ID('tempdb..#Segment_ToUseScaling') IS NOT NULL DROP TABLE #Segment_ToUseScaling
	SELECT	a.ClubID
			,a.ClubName
			,a.BrandID
			,Shopper_Segment
	INTO	#Segment_ToUseScaling
	FROM	#Segment_CoreData a
	JOIN	#Universal_ToUseScaling b
		ON	a.ClubName = b.ClubName
		AND a.BrandID = b.BrandID
	GROUP BY a.ClubID
			,a.ClubName
			,a.BrandID
			,Shopper_Segment

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_PubScaling_Segment
		SELECT	ClubID
				,ClubName
				,Shopper_Segment AS ShopperSegment
				,AVG(PubScaling) AS PubRRScaling
		FROM	(
					SELECT		CASE
									WHEN a.ClubName = 'R4G' THEN NULL
									ELSE a.ClubID
								END AS ClubID
								,a.Clubname
								,a.BrandID
								,a.Shopper_Segment
								,CASE
									WHEN PubScaling < 0.3 THEN 0.3
									WHEN 3 < PubScaling THEN 3 
									ELSE PubScaling
								 END AS PubScaling
					FROM		#Segment_CoreData a
					INNER JOIN	#Segment_ToUseScaling b
							ON	a.Shopper_Segment = b.Shopper_Segment
							AND a.BrandID = b.BrandID
							AND	a.ClubName = b.ClubName
					INNER JOIN	#Universal_ToUseScaling c
							ON	a.BrandID = c.BrandID
							AND	a.ClubName = c.ClubName
				) c 
		GROUP BY ClubID
				,ClubName
				,Shopper_Segment
		ORDER BY ClubName
				,Shopper_Segment

END
