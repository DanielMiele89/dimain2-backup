
CREATE PROCEDURE [Staging].[SSRS_R0211_RedemptionTracker_Charity]
AS
	BEGIN
	
/*******************************************************************************************************************************************
	1. Declare Variables
*******************************************************************************************************************************************/

	DECLARE @RedeemID NVARCHAR(MAX) = '7241'

	DECLARE @Today DATE = DATEADD(DAY, 0, GETDATE())
		
/*******************************************************************************************************************************************
	2. Split multiple Redeem IDs if necessary and fetch all offers
*******************************************************************************************************************************************/
			  
	IF OBJECT_ID('tempdb..#RedeemIDs') IS NOT NULL DROP TABLE #RedeemIDs;
	SELECT r.*
	INTO #RedeemIDs
	FROM [SLC_REPL].[dbo].[Redeem]  r
	INNER JOIN [dbo].[il_SplitDelimitedStringArray] (@RedeemID, ',') ri
		ON ri.Item = r.ID
	WHERE r.FulfillmentTypeId = 6
	OR Description LIKE '%donate%'

/*******************************************************************************************************************************************
	3. Pull out a list of Cancelled redemptions
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Cancelled') IS NOT NULL DROP TABLE #Cancelled
	SELECT ItemID AS TransID
		 , 1 AS Cancelled
	INTO #Cancelled
	FROM [SLC_REPL].[dbo].[Trans] t2
	WHERE t2.TypeID = 4

	CREATE CLUSTERED INDEX cix_Cancelled_ItemID ON #Cancelled (TransID)

		
/*******************************************************************************************************************************************
	4. Pull out a list of redemptions excluding those later cancelled
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT	t.FanID
		,	t.ID
		,	t.Date
		,	t.Price
		,	t.[Option]
		,	t.ItemID
	INTO #Trans
	FROM [SLC_REPL].[dbo].[Trans] t
	WHERE EXISTS (	SELECT 1
					FROM #RedeemIDs r
					WHERE r.id = t.ItemID)
	AND t.TypeID = 3
	AND T.Points > 0
	AND t.Date < @Today

	IF OBJECT_ID('tempdb..#Redemptions') IS NOT NULL DROP TABLE #Redemptions
	SELECT t.FanID
		 , c.CompositeID
		 , t.ID AS TranID
		 , MIN(t.Date) AS RedeemDate
		 , CONVERT(DATE, MIN(t.Date)) AS RedeemDate_Date
		 , ri.RedeemType
		 , r.Description AS RedemptionDescription
		 , t.Price AS CashbackUsed
		 , CASE
				WHEN t.[Option] = 'Yes I am a UK tax payer and eligible for gift aid' THEN 1
				ELSE 0
		   END AS GiftAid
	INTO #Redemptions        
	FROM [Relational].[Customer] c
	INNER JOIN [SLC_REPL].[dbo].[Trans] t
		ON t.FanID = c.FanID
	INNER JOIN [SLC_REPL].[dbo].[RedeemAction] ra
		ON t.ID = ra.TransID
		AND ra.Status IN (1,6)
	INNER JOIN #RedeemIDs r
		ON r.id = t.ItemID
	LEFT JOIN [Relational].[RedemptionItem] ri
		ON t.ItemID = ri.RedeemID
	WHERE NOT EXISTS (SELECT 1
					FROM #Cancelled ca
					WHERE ca.TransID = T.ID)
	GROUP BY t.FanID
		   , c.CompositeID
		   , t.ID
		   , ri.RedeemType
		   , r.[Description]
		   , t.[Option]
		   , t.Price

	CREATE CLUSTERED INDEX CIX_DateFanID ON #Redemptions (RedeemDate_Date, FanID)
		
/*******************************************************************************************************************************************
	6. Fetch customer detailes
*******************************************************************************************************************************************/
		
	/*******************************************************************************************************************************************
		6.1. Fetch customers Loyalty Segments
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#LoyaltySegment') IS NOT NULL DROP TABLE #LoyaltySegment
		SELECT FanID
			 , CASE
					WHEN CustomerSegment LIKE '%v%' THEN 'Premier'
					ELSE 'Core'
			   END AS LoyaltySegment
		INTO #LoyaltySegment
		FROM [Relational].[Customer_RBSGSegments] sg
		WHERE EndDate IS NULL

		CREATE CLUSTERED INDEX CIX_FanID ON #LoyaltySegment (FanID)

			
/*******************************************************************************************************************************************
	8. Combine donation data into final table, accounting for Gift Aid
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#RedemptionData') IS NOT NULL DROP TABLE #RedemptionData
	SELECT re.FanID
		 , cl.Name AS ClubName
		 , ls.LoyaltySegment
		 , CashbackUsed
		 , CashbackUsed + (GiftAid * 0.25 * CashbackUsed) AS CashbackUsedPlusGiftAid
		 , 1 AS Redemptions
		 , GiftAid
		 , CONVERT(DATE, RedeemDate) AS RedeemDate
		 , RedeemDate AS RedeemDateTime
	INTO #RedemptionData
	FROM #Redemptions re
	INNER JOIN #LoyaltySegment ls
		ON re.FanID = ls.FanID
	INNER JOIN [SLC_REPL].[dbo].[Fan] fa
		ON re.FanID = fa.ID
	INNER JOIN [SLC_REPL].[dbo].[Club] cl
		ON fa.ClubID = cl.ID
	WHERE RedeemDate BETWEEN '2022-03-03' AND @Today
		
		
/*******************************************************************************************************************************************
	8. Fetch web login data
*******************************************************************************************************************************************/

	IF OBJECT_ID('tempdb..#TrackingData') IS NOT NULL DROP TABLE #TrackingData
	SELECT cu.FanID
		 , cl.Name AS ClubName
		 , ls.LoyaltySegment
		 , CONVERT(DATE, wl.trackdate) AS LoginDate
	INTO #TrackingData
	FROM [Relational].[WebLogins] wl
	INNER JOIN #LoyaltySegment ls
		ON wl.fanid = ls.FanID
	INNER JOIN [Relational].[Customer] cu
		ON wl.fanid = cu.FanID
	INNER JOIN [SLC_REPL].[dbo].[Club] cl
		ON cu.ClubID = cl.ID
	WHERE trackdate BETWEEN '2022-03-03' AND @Today

	
/*******************************************************************************************************************************************
	9. Aggregate results
*******************************************************************************************************************************************/
		
	/*******************************************************************************************************************************************
		9.1. Aggregate Donations
	*******************************************************************************************************************************************/
		
		IF OBJECT_ID('tempdb..#RedemptionData_Agg') IS NOT NULL DROP TABLE #RedemptionData_Agg
		SELECT ClubName
			 , LoyaltySegment
			 , CONVERT(DATE, RedeemDate) AS RedeemDate
			 , SUM(CashbackUsed) AS CashbackUsed
			 , SUM(CashbackUsedPlusGiftAid) AS CashbackUsedPlusGiftAid
			 , SUM(Redemptions) AS Redemptions
			 , SUM(GiftAid) AS GiftAid
		INTO #RedemptionData_Agg
		FROM #RedemptionData rd
		GROUP BY ClubName
			   , LoyaltySegment
			   , CONVERT(DATE, RedeemDate)

	/*******************************************************************************************************************************************
		9.2. Aggregate Tracking Data
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#TrackingData_Agg') IS NOT NULL DROP TABLE #TrackingData_Agg
		SELECT ClubName
			 , LoyaltySegment
			 , CONVERT(DATE, LoginDate) AS RedeemDate
			 , COUNT(1) AS Logins
			 , COUNT(DISTINCT FanID) AS CustomersLoggingIn
		INTO #TrackingData_Agg
		FROM #TrackingData td
		GROUP BY ClubName
			   , LoyaltySegment
			   , CONVERT(DATE, LoginDate)
	
/*******************************************************************************************************************************************
	10. Output for report
*******************************************************************************************************************************************/

	;WITH
	Dates AS (	SELECT DISTINCT
					   ClubName
					 , LoyaltySegment
					 , RedeemDate
				FROM #RedemptionData_Agg
				UNION
				SELECT DISTINCT
					   ClubName
					 , LoyaltySegment
					 , RedeemDate
				FROM #TrackingData_Agg)

	SELECT da.ClubName
		 , da.LoyaltySegment
		 , da.RedeemDate
		 , COALESCE(rd.CashbackUsed, 0) AS CashbackUsed
		 , COALESCE(rd.CashbackUsedPlusGiftAid, 0) AS CashbackUsedPlusGiftAid
		 , COALESCE(rd.Redemptions, 0) AS Redemptions
		 , COALESCE(rd.GiftAid, 0) AS GiftAid
		 , COALESCE(td.CustomersLoggingIn, 0) AS CustomersLoggingIn
	FROM Dates da
	LEFT JOIN #RedemptionData_Agg rd
		ON da.RedeemDate = rd.RedeemDate
		AND da.ClubName = rd.ClubName
		AND da.LoyaltySegment = rd.LoyaltySegment
	LEFT JOIN #TrackingData_Agg td
		ON da.RedeemDate = td.RedeemDate
		AND da.ClubName = td.ClubName
		AND da.LoyaltySegment = td.LoyaltySegment
	ORDER BY da.RedeemDate ASC
		   , da.ClubName
		   , da.LoyaltySegment


	--SELECT *
	--FROM Warehouse.Staging.NETCharityResults
	--ORDER BY RedeemDate ASC
	--	   , ClubName
	--	   , LoyaltySegment


END

