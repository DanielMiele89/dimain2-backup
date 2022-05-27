


-- *****************************************************************************************************
-- Author:		Ijaz Amjad
-- Create date: 26/10/2016
-- Description: Shows the difference in number of Outlets (monthly).
-- *****************************************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0136_RetailerOutletTrackingV2](
				@Status INT,
				--@PartnerID INT,
				@Date DATE
				)
						
	WITH EXECUTE AS OWNER		
AS

	SET NOCOUNT ON;


DECLARE			@s INT,
				--@PID INT,
				@Today DATE
SET				@s = @Status
--SET				@PID = @PartnerID
SET				@Today = GETDATE()

/***************************************************************************
************** All MIDs for the specified PartnerID (nFI) ******************
***************************************************************************/
IF OBJECT_ID ('tempdb..#MIDs_nFI') IS NOT NULL DROP TABLE #MIDs_nFI
SELECT			PartnerID
,				ID
,				MerchantID
INTO			#MIDs_nFI
FROM			nFI.Relational.Outlet
--WHERE			PartnerID = @PID

CREATE CLUSTERED INDEX IDX_OutletID ON #MIDs_nFI (ID)




/***************************************************************************
********** Pulls Tran data monthly for the last year (nFI) *****************
***************************************************************************/
IF OBJECT_ID ('tempdb..#TranData_nFI') IS NOT NULL DROP TABLE #TranData_nFI
SELECT			mid.PartnerID
,				YEAR(m.TransactionDate) AS TransactionYear
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
GROUP BY		mid.PartnerID
,				YEAR(m.TransactionDate)
,				MONTH(m.TransactionDate)


/***************************************************************************
***************** Calculates difference in Oulets (nFI) ********************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Outlets_nFI') IS NOT NULL DROP TABLE #Outlets_nFI
SELECT			*
,				Outlets - LEAD(Outlets,1) OVER(PARTITION BY PartnerID ORDER BY CAST(CONCAT(TransactionYear, '-', TransactionMonth, '-', '01') AS DATE) DESC ) AS OutletsDifference
INTO			#Outlets_nFI
FROM			#TranData_nFI


/***************************************************************************
********************** Populate Table (nFI data) ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#nFI_Data') IS NOT NULL DROP TABLE #nFI_Data
SELECT			PartnerID
,				TransactionYear AS Year
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
SELECT			PartnerID
,				OutletID
,				MerchantID
INTO			#MIDs_RBS
FROM			Warehouse.Relational.Outlet
--WHERE			PartnerID = @PID

CREATE CLUSTERED INDEX IDX_OutletID ON #MIDs_RBS (OutletID)


/***************************************************************************
********** Pulls Tran data monthly for the last year (RBS) *****************
***************************************************************************/
IF OBJECT_ID ('tempdb..#TranData_RBS') IS NOT NULL DROP TABLE #TranData_RBS
SELECT			mid.PartnerID,
				YEAR(pt.TransactionDate) AS TransactionYear
,				MONTH(pt.TransactionDate) AS TransactionMonth
,				SUM(pt.TransactionAmount) AS Amount 
,				COUNT(DISTINCT pt.OutletID) AS Outlets
INTO			#TranData_RBS
FROM			#MIDs_RBS AS mid
INNER JOIN		Warehouse.Relational.PartnerTrans AS pt
		ON		mid.OutletID = pt.OutletID
		AND		pt.TransactionDate			BETWEEN DATEADD(MONTH,-11,DATEADD(MONTH,-1,DATEADD(DAY,(-DAY(@Today))+1,@Today)))
											AND		DATEADD(DAY,-DAY(@Today),CAST(@Today AS DATE))
GROUP BY		mid.PartnerID
,				YEAR(pt.TransactionDate)
,				MONTH(pt.TransactionDate)


/***************************************************************************
***************** Calculates difference in Oulets (RBS) ********************
***************************************************************************/
IF OBJECT_ID ('tempdb..#Outlets_RBS') IS NOT NULL DROP TABLE #Outlets_RBS
SELECT			*
,				Outlets - LEAD(Outlets,1) OVER(PARTITION BY PartnerID ORDER BY CAST(CONCAT(TransactionYear, '-', TransactionMonth, '-', '01') AS DATE) DESC ) AS OutletsDifference
INTO			#Outlets_RBS
FROM			#TranData_RBS


/***************************************************************************
********************** Populate Table (RBS data) ***************************
***************************************************************************/
IF OBJECT_ID ('tempdb..#RBS_Data') IS NOT NULL DROP TABLE #RBS_Data
SELECT			PartnerID
,				TransactionYear AS Year
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
SELECT	YEAR(StartDate) AS Year, MONTH(StartDate) AS Month
INTO	#AllDates
FROM	cDates

INSERT INTO		Warehouse.Staging.R_0136_RetailerOutletTracking
				(Year, Month, PartnerID, PartnerName )
SELECT			Year AS Year
,				Month AS Month
,				p.ID AS PartnerId
,				p.Name AS PartnerName
FROM			#AllDates AS ad
CROSS JOIN		(	SELECT		ID
					,			Name
					FROM		SLC_Report.dbo.Partner
					WHERE		(STATUS IN (@s) OR (@s IS NULL AND STATUS IN (1,3)))
---						AND		Matcher IN (4,10,11,12,15,17,19,24,25,31,32,35,36,37,38,39,40,41)
				) AS p

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
		ON		rot.PartnerID = n.PartnerID
		AND		rot.Year = n.Year
		AND		rot.Month = n.Month
LEFT JOIN		#RBS_Data AS r
		ON		rot.PartnerID = r.PartnerID
		AND		rot.Year = r.Year
		AND		rot.Month = r.Month


--Delete from Warehouse.Staging.R_0136_RetailerOutletTracking
--Where Amount_nFI is null and Amount_RBS is null

DELETE a FROM Warehouse.Staging.R_0136_RetailerOutletTracking a
JOIN (

	SELECT PartnerName FROM (
		SELECT PartnerName, SUM(Amount_NFI) nFIAm, SUM(Amount_RBS) rbsAM 
		FROM Warehouse.Staging.R_0136_RetailerOutletTracking
		GROUP BY PartnerName
	) x
	WHERE nFIAm IS NULL and rbsAM IS NULL
) x on x.PartnerName = a.PartnerName


/***************************************************************************
*************************** Display Table **********************************
***************************************************************************/
SELECT			PartnerID
,				PartnerName
,				Year
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
ORDER BY		PartnerName
,				Year
,				CAST(Month AS INT)


--DECLARE @Date AS DATE
--SET		@Date = GETDATE()

--EXEC Staging.SSRS_R0136_RetailerOutletTrackingV2 @Date
GO
GRANT EXECUTE
    ON OBJECT::[Staging].[SSRS_R0136_RetailerOutletTrackingV2] TO [gas]
    AS [dbo];

