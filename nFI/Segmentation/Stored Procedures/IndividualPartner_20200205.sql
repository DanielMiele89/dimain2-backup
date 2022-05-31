
CREATE PROCEDURE [Segmentation].[IndividualPartner_20200205] (@PartnerID INT, @CycleDate DATE)
AS
BEGIN
-------------------------------------------------------------------
--		Declare and set variables
-------------------------------------------------------------------

--DECLARE @PartnerID INT = 3433
--SET @ToBeRanked = 0


DECLARE @Acquire SMALLINT
	  , @Lapsed SMALLINT
	  , @Shopper SMALLINT
	  , @Registered SMALLINT

	  , @AcquireDate DATE	-- Date on or after which a transacrion is deem Acquire
	  , @LapsedDate DATE	-- Date on or after which a transaction is deemed Lapsed
	  , @ShopperDate DATE	-- Date on or after which a transacrion is deem Shopper
	  
	  , @ShopperCount INT = 0
	  , @LapsedCount INT = 0
	  , @AcquireCount INT = 0
	  
	  , @ErrorCode INT
	  , @ErrorMessage NVARCHAR(MAX)
	  , @ErrorLine int
	  , @EndDate date
	  , @StartDate date
	  , @RowCount int
	  , @CurrentDate date
	  , @time DATETIME
	  , @msg VARCHAR(2048)

Set @EndDate =		Dateadd(day,DATEDIFF(dd, 0, @CycleDate)-1,0)
Set @StartDate =	Dateadd(day,DATEDIFF(dd, 0, @CycleDate)-0,0)
		

SELECT @Acquire = Acquire
	 , @Lapsed = Lapsed
	 , @Shopper = Shopper
	 , @Registered = RegisteredAtLeast 
FROM [Warehouse].[Segmentation].[ROC_Shopper_Segment_Partner_Settings]
WHERE PartnerID = @PartnerID
AND EndDate IS NULL

		-------------------------------------------------------------------
		--		Get details for relevant partner
		-------------------------------------------------------------------
				
			IF OBJECT_ID('tempdb..#Partner') IS NOT NULL DROP TABLE #Partner
			--Find Partner Record
				select	p.PartnerID as ID,
						p.PartnerName as name
				into	#Partner
				from	Relational.Partner as p
				Where	p.PartnerID = @PartnerID
			Union All
				--Find Secondary Partner Record
				select	p.PartnerID
						,p.PartnerName
				from	Relational.Partner as p
				inner Join Warehouse.[iron].[PrimaryRetailerIdentification] as a
					on p.PartnerID = a.PartnerID
				Where a.PrimaryPartnerID = @PartnerID
			

		-------------------------------------------------------------------
		--		Get Outlets for relevant partner
		-------------------------------------------------------------------
				
			IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
			SELECT ro.PartnerID
				 , ro.ID AS RetailOutletID
			INTO #RetailOutlet
			FROM #Partner pa
			INNER JOIN [SLC_Report].[dbo].[RetailOutlet] ro
				ON pa.ID = ro.PartnerID

			CREATE CLUSTERED INDEX CIX_PanID on #RetailOutlet (RetailOutletID) 
						
	
		-------------------------------------------------------------------
		--		Set up tables to get transactions
		-------------------------------------------------------------------
	

		Set @CurrentDate =	@CycleDate
		Set @AcquireDate =	(Select DATEADD(month, -(@Acquire), @CurrentDate))
		Set @LapsedDate  =	(Select DATEADD(month, -(@Lapsed),  @CurrentDate))
		Set @ShopperDate =	(Select DATEADD(month, -(@Shopper), @CurrentDate))

	
		IF OBJECT_ID('tempdb..#TrackedRetailSpend') IS NOT NULL DROP TABLE #TrackedRetailSpend
		Create Table #TrackedRetailSpend (	FanID int,
											Segment	int )
											
		IF OBJECT_ID('tempdb..#Customerspend') IS NOT NULL DROP TABLE #Customerspend
		Create Table #Customerspend (CompositeID Bigint,
									LatestTran date)	 

		-------------------------------------------------------------------
		--		Get tracked transactions for retailer
		-------------------------------------------------------------------
			
			INSERT INTO #Customerspend
			SELECT cu.CompositeID
				 , MAX(TransactionDate) AS LatestTran
			FROM ##CustomerPans cu
			INNER JOIN [SLC_Report].[dbo].[Match] ma
				ON cu.PanID = ma.PanID
			WHERE ma.TransactionDate BETWEEN @AcquireDate AND @CurrentDate
			AND EXISTS (SELECT 1
						FROM #RetailOutlet ro
						WHERE ma.RetailOutletID = ro.RetailOutletID)
			GROUP BY cu.CompositeID

			INSERT INTO #TrackedRetailSpend
			SELECT c.FanID
				 , CASE 
						WHEN LatestTran >= @LapsedDate THEN 9
						WHEN LatestTran >= @AcquireDate THEN 8
						ELSE 7
				   END AS Segment
			FROM ##Customers c
			LEFT JOIN #Customerspend cs
				ON cs.CompositeID = c.CompositeID

			CREATE CLUSTERED INDEX CIX_FanID ON #TrackedRetailSpend (FanID, Segment)

		-------------------------------------------------------------------
		--		Update members in Shopper_Segment_Members
		-------------------------------------------------------------------
		
			--*** Close old entries
			Update	a
			Set		a.EndDate = @EndDate 
			FROM	#TrackedRetailSpend as s
			Inner Join [Segmentation].[Roc_Shopper_Segment_Members_20200205] as a
				on	a.FanID = s.FanID and
					a.PartnerID = @PartnerID and
					a.EndDate is null and
					a.ShopperSegmentTypeID <> s.Segment


			-- *** Add new entries
			Insert into [Segmentation].[Roc_Shopper_Segment_Members_20200205]
			Select	s.FanID,
					@PartnerID as PartnerID,
					s.Segment as ShopperSegmentTypeID,
					@StartDate,
					NULL
			FROM #TrackedRetailSpend as s
			WHERE NOT EXISTS (	SELECT 1
								FROM [Segmentation].[Roc_Shopper_Segment_Members_20200205] sg
								WHERE sg.PartnerID = @PartnerID
								AND sg.EndDate IS NULL
								AND s.FanID = sg.FanID)


INSERT INTO Warehouse.Prototype.SegmentationLog
SELECT @PartnerID, @CycleDate	

END

