


/********************************************************************************************
** Name: R_0168 - Branded Acquirers
** Desc: Displays the brands and their acquirers for the previous 2 months
** Auth: Code written by Ajith Asokan, Deployed by Zoe Taylor
** Date: 03/08/2017
*********************************************************************************************
** Change History
** ---------------------
** 04/08/2017  Zoe Taylor 
			Modified to remove dynamic SQL and include only one pivot table in order to 
			make column names static

	19/09/2017 Zoe Taylor
			Changing to only show acquirers we can track
   
*********************************************************************************************/



CREATE procedure [Staging].[SSRS_R_0168_BrandedAcquirers] 
As
Begin
------------------------------------------------------------------------------------------------------
----------------FROM ConsumerCombination Data pull only branded ConsumerCombinationIDs----------------
------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#AcquirerCC') IS NOT NULL DROP TABLE #AcquirerCC
	SELECT cc.ConsumerCombinationID
		 , cc.LocationCountry
		 , cc.MID
		 , cc.BrandID
		 , br.BrandName
		 , br.SectorID
		 , a.AcquirerName
	INTO #AcquirerCC
	FROM Relational.ConsumerCombination cc
	INNER JOIN Warehouse.Relational.brand br
		ON br.BrandID = cc.BrandID
	LEFT JOIN MI.RetailerTrackingAcquirer rt
		ON cc.ConsumerCombinationID = rt.ConsumerCombinationID
	INNER JOIN Relational.Acquirer AS a
		ON rt.AcquirerID = a.AcquirerID
	WHERE cc.BrandID != 944
	AND br.SectorID != 1

	CREATE CLUSTERED INDEX CC_IDX ON #AcquirerCC(ConsumerCombinationID)


--------------------------------------------------------------------------------------------------------
---------Pull out ConsumerCombinationID for transactions between last month and the month before-------
--------------------------------------------------------------------------------------------------------

	DECLARE	@StartDate DATE = DATEADD(day, 1, EOMONTH(GETDATE(), -3))
		  , @EndDate DATE = EOMONTH(GETDATE(), -1)

	IF OBJECT_ID('tempdb..#AcquirerCT') IS NOT NULL DROP TABLE #AcquirerCT
	SELECT ct.ConsumerCombinationID
		 , EOMONTH(TranDate) AS TranMonth
		 , SUM(Amount) Amount 
		 , COUNT(1) No_Trans
	INTO #AcquirerCT
	FROM [Relational].[ConsumerTransaction] ct
	WHERE TranDate BETWEEN @StartDate AND @EndDate
	AND EXISTS (SELECT 1
				FROM #AcquirerCC cc
				WHERE ct.ConsumerCombinationID = cc.ConsumerCombinationID)
	GROUP BY ct.ConsumerCombinationID
		   , EOMONTH(TranDate)

-------------------------------------------------------------------------------------------------------
----------------PULL out the Acquirer attached to each ConsumerCombinationID---------------------------
-------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('Tempdb..#branded_Aqx') IS NOT NULL DROP TABLE #branded_Aqx
	SELECT cc.BrandName
		 , cc.BrandID 
		 , cc.AcquirerName
		 , cc.LocationCountry
		 , ISNULL(COUNT(DISTINCT cc.MID), 0) [Count of MIDs]
		 , TranMonth 
		 , ISNULL(SUM(Amount),0) Amount
		 , ISNULL(SUM(No_Trans),0) No_Trans
	INTO #branded_Aqx
	FROM #AcquirerCC AS cc
	INNER JOIN #AcquirerCT CT
		ON cc.ConsumerCombinationID=ct.ConsumerCombinationID
	GROUP BY cc.BrandName
		, cc.BrandID 
		, cc.AcquirerName 
		, cc.LocationCountry
		, TranMonth


	IF OBJECT_ID('tempdb..#Branded_Aq') IS NOT NULL DROP TABLE #Branded_Aq
	SELECT * 
		, CASE TranMonth WHEN x.MinDate THEN 'Previous' ELSE 'Current' END Period
	INTO #Branded_Aq
	FROM (
		SELECT 
			*
			, MIN(TranMonth) OVER (ORDER BY BrandID) MinDate
			, MAX(TranMonth) OVER (ORDER BY BrandID) MaxDate
		FROM #Branded_Aqx
	) x
	
-------------------------------------------------------------------------------------------------------
------------------Create first pivot table for the Amount----------------------------------------------
-------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb.dbo.#Acquirer') IS NOT NULL DROP TABLE #Acquirer
	
		SELECT  BrandName
				, BrandID
				, AcquirerName
				, LocationCountry
				, MAX(PreviousAmount) PreviousAmount
				, MAX(CurrentAmount) CurrentAmount
				, MAX(PreviousTran) PreviousTran
				, MAX(CurrentTran) CurrentTran
				, MAX(PreviousMIDs) PreviousMIDs
				, MAX(CurrentMIDs) CurrentMIDs
		INTO #Acquirer
		FROM (
			SELECT BrandName
				, BrandID
				, AcquirerName
				, LocationCountry
				, Amount
				, [Count Of Mids] as [NoOfMIDs]
				, [no_trans] as [NoOfTrans]
				, Period + 'Amount' AS PeriodAmount
				, Period + 'Tran' AS PeriodTran
				, Period + 'MIDs' AS PeriodMIDs
			FROM #branded_Aq
		) x
		pivot 
		(	SUM(amount)
			for PeriodAmount in ([PreviousAmount], [CurrentAmount]) 
		) AS Total_AMOUNT
		pivot 
		(	SUM([NoOfTrans])
			for PeriodTran in ([PreviousTran], [CurrentTran]) 
		) AS y
		pivot 
		(	SUM([NoOfMids])
			for PeriodMids in ([PreviousMIDs], [CurrentMIDs]) 
		) AS z
		GROUP BY BrandName
				, BrandID
				, AcquirerName
				, LocationCountry



		SELECT * 
			, isnull(
						(100*PreviousTran/SUM(PreviousTran) OVER(Partition By BrandID))
					, 0) as [ProportionTrans]
		FROM #Acquirer

End