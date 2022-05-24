


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 20/10/2016
-- Description: Shows the difference in number of Outlets (monthly).
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0136_RetailerOutletTracking](
				@PartnerID INT,
				@Date DATE
				)
						
			
AS

	SET NOCOUNT ON;


DECLARE			@PID INT,
				@Today DATE
SET				@PID = @PartnerID
SET				@Today = GETDATE()

/***************************************************************************
************** All MIDs for the specified PartnerID (nFI) ******************
***************************************************************************/
IF OBJECT_ID ('tempdb..#MIDs_nFI') IS NOT NULL DROP TABLE #MIDs_nFI
SELECT			ID
,				MerchantID
INTO			#MIDs_nFI
FROM			nFI.Relational.Outlet
WHERE			PartnerID = @PID

CREATE CLUSTERED INDEX IDX_OutletID ON #MIDs_nFI (ID)


/***************************************************************************
********** Pulls Tran data monthly for the last year (nFI) *****************
***************************************************************************/
IF OBJECT_ID ('tempdb..#TranData_nFI') IS NOT NULL DROP TABLE #TranData_nFI
SELECT			YEAR(m.TransactionDate) AS TransactionYear
,				MONTH(m.TransactionDate) AS TransactionMonth
,				SUM(m.Amount) AS Amount 
,				COUNT(DISTINCT m.RetailOutletID) AS Outlets
INTO			#TranData_nFI
FROM			#MIDs_nFI AS mid
INNER JOIN		SLC_Report.dbo.Match AS m
		ON		mid.ID = m.RetailOutletID
		AND		m.TransactionDate			BETWEEN DATEADD(MONTH,-11,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(@Today))+1,@Today)))
											AND		DATEADD(DAY,-DAY(@Today),CAST(@Today AS DATE))
WHERE			m.VectorID NOT IN (37)	------------------------------------------------------------------------------------------(( VectorID 37 = RBSG ))
GROUP BY		YEAR(m.TransactionDate)
,				MONTH(m.TransactionDate)


/***************************************************************************
***************** Calculates difference in Oulets (nFI) ********************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Outlets_nFI') IS NOT NULL DROP TABLE #Outlets_nFI
SELECT			*
,				Outlets - LEAD(Outlets,1) OVER(ORDER BY CAST(CONCAT(TransactionYear, '-', TransactionMonth, '-', '01') AS DATE) DESC ) AS OutletsDifference
INTO			#Outlets_nFI
FROM			#TranData_nFI


/***************************************************************************
********************** Populate Table (nFI data) ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#nFI_Data') IS NOT NULL DROP TABLE #nFI_Data
SELECT			TransactionYear AS Year
,				TransactionMonth AS Month
,				Amount AS Amount_nFI
,				Outlets AS Outlets_nFI
,				OutletsDifference AS OutletsDifference_nFI
INTO			#nFI_Data
FROM			#Outlets_nFI


/***************************************************************************
************** All MIDs for the specified PartnerID (RBS) ******************
***************************************************************************/
IF OBJECT_ID ('tempdb..#MIDs_RBS') IS NOT NULL DROP TABLE #MIDs_RBS
SELECT			OutletID
,				MerchantID
INTO			#MIDs_RBS
FROM			Warehouse.Relational.Outlet
WHERE			PartnerID = @PID

CREATE CLUSTERED INDEX IDX_OutletID ON #MIDs_RBS (OutletID)


/***************************************************************************
********** Pulls Tran data monthly for the last year (RBS) *****************
***************************************************************************/
IF OBJECT_ID ('tempdb..#TranData_RBS') IS NOT NULL DROP TABLE #TranData_RBS
SELECT			YEAR(pt.TransactionDate) AS TransactionYear
,				MONTH(pt.TransactionDate) AS TransactionMonth
,				SUM(pt.TransactionAmount) AS Amount 
,				COUNT(DISTINCT pt.OutletID) AS Outlets
INTO			#TranData_RBS
FROM			#MIDs_RBS AS mid
INNER JOIN		Warehouse.Relational.PartnerTrans AS pt
		ON		mid.OutletID = pt.OutletID
		AND		pt.TransactionDate			BETWEEN DATEADD(MONTH,-11,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(@Today))+1,@Today)))
											AND		DATEADD(DAY,-DAY(@Today),CAST(@Today AS DATE))
GROUP BY		YEAR(pt.TransactionDate)
,				MONTH(pt.TransactionDate)


/***************************************************************************
***************** Calculates difference in Oulets (RBS) ********************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Outlets_RBS') IS NOT NULL DROP TABLE #Outlets_RBS
SELECT			*
,				Outlets - LEAD(Outlets,1) OVER(ORDER BY CAST(CONCAT(TransactionYear, '-', TransactionMonth, '-', '01') AS DATE) DESC ) AS OutletsDifference
INTO			#Outlets_RBS
FROM			#TranData_RBS


/***************************************************************************
********************** Populate Table (RBS data) ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#RBS_Data') IS NOT NULL DROP TABLE #RBS_Data
SELECT			TransactionYear AS Year
,				TransactionMonth AS Month
,				Amount AS Amount_RBS
,				Outlets AS Outlets_RBS
,				OutletsDifference AS OutletsDifference_RBS
INTO			#RBS_Data
FROM			#Outlets_RBS


/***************************************************************************
********* Truncate and refresh Display Table with dates ********************
***************************************************************************/
TRUNCATE TABLE	Warehouse.Staging.R_0136_RetailerOutletTracking

;WITH cDates
AS
(
	SELECT 1 AS ID, DATEADD(MONTH,-11,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(@Today))+1,@Today))) AS StartDate
	UNION ALL
	SELECT ID+1, DATEADD(MONTH, 1, StartDate)
	FROM cDates
	WHERE ID < 12
)
SELECT YEAR(StartDate) AS Year, MONTH(StartDate) AS Month
INTO #AllDates
FROM cDates

INSERT INTO		Warehouse.Staging.R_0136_RetailerOutletTracking
				(Year, Month)
SELECT			Year AS Year
,				Month AS Month
FROM			#AllDates

DROP TABLE #AllDates


/***************************************************************************
************* Populate Display Table (nFI & RBS Data) **********************
***************************************************************************/
UPDATE			Warehouse.Staging.R_0136_RetailerOutletTracking
SET				Amount_nFI = n.Amount_nFI
,				Outlets_nFI = n.Outlets_nFI
,				OutletsDifference_nFI = n.OutletsDifference_nFI
,				Amount_RBS = r.Amount_RBS
,				Outlets_RBS = r.Outlets_RBS
,				OutletsDifference_RBS = r.OutletsDifference_RBS
FROM			Warehouse.Staging.R_0136_RetailerOutletTracking AS rot
LEFT JOIN		#nFI_Data AS n
		ON		rot.Year = n.Year
		AND		rot.Month = n.Month
LEFT JOIN		#RBS_Data AS r
		ON		rot.Year = r.Year
		AND		rot.Month = r.Month


/***************************************************************************
*************************** Display Table **********************************
***************************************************************************/
SELECT			Year
,				CASE
					WHEN Month = '1'		THEN 'January'
					WHEN Month = '2'		THEN 'February'
					WHEN Month = '3'		THEN 'March'
					WHEN Month = '4'		THEN 'April'
					WHEN Month = '5'		THEN 'May'
					WHEN Month = '6'		THEN 'June'
					WHEN Month = '7'		THEN 'July'
					WHEN Month = '8'		THEN 'August'
					WHEN Month = '9'		THEN 'September'
					WHEN Month = '10'		THEN 'October'
					WHEN Month = '11'		THEN 'November'
					WHEN Month = '12'		THEN 'December'
				END AS Month
,				Amount_nFI
,				Outlets_nFI
,				OutletsDifference_nFI
,				Amount_RBS
,				Outlets_RBS
,				OutletsDifference_RBS		
FROM			Warehouse.Staging.R_0136_RetailerOutletTracking
ORDER BY		Year
,				CAST(Month AS INT)


--DECLARE @Date AS DATE
--SET		@Date = GETDATE()

--EXEC Staging.SSRS_R0136_RetailerOutletTracking 4319, @Date