


/********************************************************************************************
** Name: R_0172 - Retailer Trackability - CSView
** Desc: Displays the brands and their acquirers for the previous 2 months
** Auth: Zoe Taylor
** Date: 03/08/2017
*********************************************************************************************
** Change History
** ---------------------
** 04/08/2017  Zoe Taylor 
			Modified to remove dynamic SQL and include only one pivot table in order to 
			make column names static

** 19/09/2017 Zoe Taylor
			Change view so it only shows a trackable status for ClientServices version of 
			report
   
*********************************************************************************************/



CREATE PROCEDURE [Staging].[SSRS_R_0172_RetailerTrackability_CSView] 
AS
BEGIN

	/******************************************************************		
			Declare variables
	******************************************************************/
	DECLARE	 @StartDate DATE = DATEADD(DAY, 1, EOMONTH(GETDATE(), -3)) 
			,@EndDate DATE = EOMONTH(GETDATE(), -1)


	/******************************************************************		
			Get ConsumerCombinationID's where there is a BrandID 
			assigned 
	******************************************************************/

	IF OBJECT_ID('tempdb..#AcquirerCC') IS NOT NULL DROP TABLE #AcquirerCC
	SELECT *
	INTO #AcquirerCC
	FROM Relational.ConsumerCombination
	WHERE BrandID<>944

	CREATE CLUSTERED INDEX CC_IDX ON #AcquirerCC(ConsumerCombinationID)


	/******************************************************************		
			Get transactions for CCID for the last 2 full months 
	******************************************************************/

	IF OBJECT_ID('tempdb..#AcquirerCT') IS NOT NULL DROP TABLE #AcquirerCT
	SELECT ct.ConsumerCombinationID
		, LocationCountry
		, MID
		, SUM(Amount) Amount 
	INTO #AcquirerCT
	FROM #AcquirerCC cc
	INNER JOIN Warehouse.Relational.ConsumerTransaction CT
		ON cc.ConsumerCombinationID=ct.ConsumerCombinationID
	WHERE TranDate>= @StartDate   
		AND  TranDate<= @EndDate 
	GROUP BY ct.ConsumerCombinationID
		,MID
		,LocationCountry
		, DATEADD(MONTH, DATEDIFF(MONTH, 0, TranDate), 0) 


	/******************************************************************		
			Get trackable status for each acquirer:
				0 - Not trackable
				1 - Trackable
				2 - Trackable (WorldPay) - created dynamically in code
	******************************************************************/	

	IF OBJECT_ID('Tempdb..#branded_Aqx') IS NOT NULL DROP TABLE #branded_Aqx
	SELECT BrandName
		, cc.BrandID 
		, a.AcquirerName
		, ct.LocationCountry
		, CASE 
			WHEN AcquirerName = 'WorldPay' then 2
			ELSE a.RewardTrackable
		  END as RewardTrackable
		, ISNULL(SUM(Amount),0) Amount
	INTO #branded_Aqx
	FROM #AcquirerCC AS cc WITH (NOLOCK)
	LEFT OUTER JOIN MI.RetailerTrackingAcquirer AS rt
		ON cc.ConsumerCombinationID = rt.ConsumerCombinationID
	INNER JOIN Relational.Acquirer AS a
		ON rt.AcquirerID = a.AcquirerID
	INNER JOIN Warehouse.Relational.brand b
		ON b.BrandID=cc.BrandID
	INNER JOIN #AcquirerCT CT
		ON cc.ConsumerCombinationID=ct.ConsumerCombinationID
	WHERE b.SectorID<>1
	GROUP BY BrandName
		, cc.BrandID 
		, a.AcquirerName 
		, ct.LocationCountry
		, a.RewardTrackable
	ORDER BY LTRIM(BrandName)
		, cc.BrandID
		, AcquirerName


	/******************************************************************		
			Get totals to use later in calculating percentages:
				* Total per brand
				* Total per brand per trackable status
	******************************************************************/

	IF OBJECT_ID('Tempdb..#AmountTrackable') IS NOT NULL DROP TABLE #AmountTrackable
	SELECT DISTINCT  
		x.BrandName
		, x.brandID
		, x.RewardTrackable 
		, SUM(Amount) OVER (PARTITION BY BrandID, RewardTrackable) [AcqTrackable] -- Total per Brand per trackable status
		, SUM(Amount) OVER (PARTITION BY brandid) [TotalTrackable] -- Total per brand
	INTO #AmountTrackable
	FROM #branded_Aqx x
	GROUP BY x.BrandName
		, x.BrandID
		, x.RewardTrackable
		, x.Amount


	/******************************************************************		
			Calculate percentages and set to 0 if negative to avoid 
			divide by zero error 
	******************************************************************/

	IF OBJECT_ID('Tempdb..#PercentTrackable') IS NOT NULL DROP TABLE #PercentTrackable
	SELECT *, 
		CASE 
			WHEN TotalTrackable = 0 THEN 0 
			ELSE ISNULL(AcqTrackable, 0)/ISNULL(TotalTrackable,0)*100
		END AS  [PercentageTrackable]
	INTO #PercentTrackable
	FROM #AmountTrackable


	/******************************************************************		
			Set TrackableStatus column based on requirements 
	******************************************************************/	

	IF OBJECT_ID('Tempdb..#FinalResults') IS NOT NULL DROP TABLE #FinalResults
	SELECT y.BrandName
			, y.BrandID
			,CASE 
				WHEN PercentageTrackable >= 90 and RewardTrackable = 2 then 'Yes (WorldPay)'
				WHEN PercentageTrackable >= 30 and RewardTrackable = 2 then 'Some (WorldPay)'
				WHEN PercentageTrackable >= 90 and RewardTrackable = 1 then 'Yes'
				WHEN PercentageTrackable >= 30 and RewardTrackable = 1 then 'Some'
				wHEN RewardTrackable = 0 then 'No'
				ELSE 'Unknown'
			END AS TrackableStatus
			, PercentageTrackable
			, RewardTrackable
	INTO #FinalResults
	FROM ( --Get maximum percentage for each trackable status
			SELECT x.BrandName
				, x.BrandID
				, x.RewardTrackable
				, x.percentagetrackable
				, ROW_NUMBER() OVER (PARTITION BY BrandID ORDER BY PercentageTrackable DESC) [rownum]			
			FROM #PercentTrackable x
	) y
	WHERE y.rownum = 1
	ORDER BY BrandName 


	/******************************************************************		
			Display final results set 
	******************************************************************/
	
	SELECT x.BrandName
		, x.TrackableStatus
		, CASE 
			WHEN x.RewardTrackable in (1, 2) THEN x.PercentageTrackable
			ELSE 0 
		END as PercentageTrackable
	FROM #FinalResults x
	ORDER BY x.BrandName
	

END


