

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_ForecastWave
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_ForecastWave]
									
AS
BEGIN
	SET NOCOUNT ON;


/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bcs.*
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_ForecastWave bcs
LEFT OUTER JOIN Warehouse.Relational.BookingCal_ForecastWave bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
	AND bcs.ForecastSubmissionDate = bcs2.ForecastSubmissionDate
	AND bcs.StartDate = bcs2.Campaign_StartDate
	AND bcs.EndDate = bcs2.Campaign_EndDate
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bcs.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_ForecastWave bcs
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_ForecastWave bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_ForecastWave
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_ForecastWave bcs
INNER JOIN #NewEntries ne
	ON bcs.ClientServicesRef = ne.ClientServicesRef
	AND bcs.Campaign_StartDate = ne.StartDate
	AND bcs.Campaign_EndDate = ne.EndDate
WHERE bcs.Status_EndDate IS NULL



/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_ForecastWave
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_ForecastWave bcs
INNER JOIN #DeletedEntries de
	ON bcs.ClientServicesRef = de.ClientServicesRef
WHERE bcs.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_ForecastWave
SELECT	ClientServicesRef,
	StartDate as Campaign_StartDate,
	EndDate as Campaign_EndDate,
	TargetedVolume,
	ControlVolume,
	CustomerBaseType,
	Base,
	AvgOfferRate,
	TotalSales,
	QualyfingSales as QualifyingSales,
	TotalIncrementalSales,
	WeeklySpenders,
	TotalSpenders,
	QualyfingSpenders as QualifyingSpenders,
	TotalIncrementalSpednders,
	TotalCashback,
	TotalOverride,
	QualyfingCashback as QualifyingCashback,
	QualyfingOverride as QualifyingOverride,
	LengthWeeks,
	ForecastSubmissionDate,
	RetailerType,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries



END