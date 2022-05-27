
-- ***********************************************************
-- Author: Suraj Chahal
-- Create date: 20/08/2015
-- Description: Updates data for Halfords Weekly Report
-- ***********************************************************
CREATE PROCEDURE [Staging].[SSRS_R0097_Quidco_HalfordsWeeklyCalculation]

AS
BEGIN
	SET NOCOUNT ON;


/**************************************
******Write entry to JobLog Table******
**************************************/
INSERT INTO staging.JobLog_Temp
SELECT	StoredProcedureName = 'SSRS_R0097_Quidco_HalfordsWeeklyCalculation',
	TableSchemaName = 'Staging',
	TableName = 'SSRS_R0097_HalfordsWeeklyReport',
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'A'



/***************************************************************************
*********************Create Weekly Stats for Halfords***********************
***************************************************************************/
IF OBJECT_ID('Warehouse.Staging.SSRS_R0097_HalfordsWeeklyReport') IS NOT NULL DROP TABLE Warehouse.Staging.SSRS_R0097_HalfordsWeeklyReport
SELECT	p.Name as PartnerName,
	p.ID as ParterID,
	hqd.[year] as Years,
	hqd.[week] as Week_No,
	SUM(m.Amount) as Trans_Amount,
	SUM(m.PartnerCommissionAmount)-sum (m.VatAmount) as Commission_exclVAT,
	SUM(tt.Multiplier * t.CommissionEarned)as Cashback,
	COUNT(1) as No_Trans,
	COUNT(DISTINCT f.compositeid) as No_Spenders,
	CAST(MIN(m.TransactionDate) AS DATE) as First_Tran, -- useful for seeing if a retailer signed up in period,
	CAST(MAX(m.TransactionDate) AS DATE) as Last_Tran, ---useful for seeing if a retailer left during period,
	MIN(hqd.Start_Date) as Start_Date,
	MAX(hqd.End_Date) as End_Date
INTO Warehouse.Staging.SSRS_R0097_HalfordsWeeklyReport
FROM SLC_Report.dbo.Fan f
INNER JOIN SLC_Report.dbo.Trans t 
	ON f.ID = t.FanID
INNER JOIN SLC_Report.dbo.Match m
	ON t.MatchID = m.ID
INNER JOIN SLC_Report.dbo.RetailOutlet ro 
	ON m.RetailOutletID = ro.ID
INNER JOIN SLC_Report.dbo.Partner p 
	ON ro.PartnerID = p.ID
INNER JOIN SLC_Report.dbo.TransactionType tt 
	ON tt.ID = t.TypeID
INNER JOIN Warehouse.InsightArchive.HalfordsQuidcoDatesLG hqd 
	ON m.TransactionDate >= hqd.[start_date] 
	ANd m.TransactionDate < (DATEADD(dd, 1,hqd.[end_date]))
WHERE   f.ClubID = 12 -- 12 is Quidco Club ID
	AND m.Status IN (1)-- Valid transaction status
        AND m.RewardStatus IN (0,1)
        AND p.ID IN (2396) -- Halfords PartnerID
        AND m.TransactionDate >= '2014-10-25' 
GROUP BY p.Name, p.id, hqd.[year], hqd.[week] 




/******************************************************************
***************Find Cardholders By Week (cumulative)***************
******************************************************************/
IF OBJECT_ID('tempdb..#RecentDates') IS NOT NULL DROP TABLE #RecentDates
SELECT	DATEADD(DAY,7,MAX(ActivationDate))as WeekDate
INTO #RecentDates
FROM Warehouse.InsightArchive.Halfords_Volumes_By_Week


DECLARE @WeekDate DATE
SET @WeekDate = (SELECT WeekDate FROM #RecentDates)

IF OBJECT_ID('tempdb..#QuidcoCumulActiveweeks') IS NOT NULL DROP TABLE #QuidcoCumulActiveweeks
SELECT	@WeekDate as ActivationDate,
	DATEPART(YEAR,(@WeekDate)) as Years,
	DATEPART(WW,(@WeekDate)) as Week_No,
	COUNT(p.ID)as No_cards,
	COUNT(DISTINCT f.ID) as No_Cardholders
INTO #QuidcoCumulActiveweeks
FROM SLC_Report.dbo.Pan p 
INNER JOIN SLC_Report.dbo.Fan f 
	ON f.CompositeID = p.CompositeID
WHERE	f.clubID = 12 -- Quidco
	AND (p.Removaldate IS NULL OR p.RemovalDate > @WeekDate)
	AND p.AdditionDate <= @WeekDate 
	AND (
		(p.DuplicationDate IS NULL OR p.DuplicationDate > @WeekDate)
		OR 
                (p.DuplicationDate <= @WeekDate AND EXISTS	
			(
			SELECT 1
			FROM SLC_Report.dbo.Pan ps 
			INNER JOIN SLC_Report.dbo.Fan fs 
				ON ps.CompositeID = fs.CompositeID
			WHERE	ps.PaymentCardID = p.PaymentCardID
				AND ps.AdditionDate BETWEEN p.AdditionDate AND @WeekDate
				AND fs.ClubID = 141 -- P4L
				) 
			)
                    )


INSERT INTO Warehouse.Insightarchive.Halfords_Volumes_By_Week
SELECT  ActivationDate,
	years,
	week_no,
	No_Cards,
	No_Cardholders
FROM #QuidcoCumulActiveweeks
WHERE ActivationDate NOT IN (SELECT DISTINCT ActivationDate FROM Warehouse.Insightarchive.Halfords_Volumes_By_Week)



/*****************************************************************
***********Update entry in JobLog Table with End Date*************
*****************************************************************/
UPDATE staging.JobLog_Temp
SET EndDate = GETDATE()
WHERE	StoredProcedureName = 'SSRS_R0097_Quidco_HalfordsWeeklyCalculation' 
	AND TableSchemaName = 'Staging'
	AND TableName = 'SSRS_R0097_HalfordsWeeklyReport' 
	AND EndDate IS NULL


/******************************************************************************
*****************Update entry in JobLog Table with Row Count*******************
******************************************************************************/
--**Count run seperately as when table grows this as a task on its own may 
--**take several minutes and we do not want it included in table creation times
UPDATE Staging.JobLog_Temp
SET TableRowCount = (SELECT COUNT(1) FROM Warehouse.Insightarchive.Halfords_Volumes_By_Week)
WHERE	StoredProcedureName = 'SSRS_R0097_Quidco_HalfordsWeeklyCalculation'
	AND TableSchemaName = 'Staging'
	AND TableName = 'SSRS_R0097_HalfordsWeeklyReport' 
	AND TableRowCount IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp



END