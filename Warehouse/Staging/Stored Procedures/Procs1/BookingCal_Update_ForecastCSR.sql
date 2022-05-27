

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_ForecastCSR
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_ForecastCSR]
									
AS
BEGIN
	SET NOCOUNT ON;


/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bcs.*
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_ForecastCSR bcs
LEFT OUTER JOIN Warehouse.Relational.BookingCal_ForecastCSR bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
	AND bcs.ForecastSubmissionDate = bcs2.ForecastSubmissionDate
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bcs.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_ForecastCSR bcs
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_ForecastCSR bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_ForecastCSR
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_ForecastCSR bcs
INNER JOIN #NewEntries ne
	ON bcs.ClientServicesRef = ne.ClientServicesRef
WHERE bcs.Status_EndDate IS NULL



/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_ForecastCSR
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_ForecastCSR bcs
INNER JOIN #DeletedEntries de
	ON bcs.ClientServicesRef = de.ClientServicesRef
WHERE bcs.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_ForecastCSR
SELECT	ClientServicesRef,
	TargetedVolume,
	AvgOfferRate,
	TotalSales,
	TotalIncrementalSales,
	TotalCashback,
	TotalOverride,
	QualyfingSales as QualifyingSales,
	QualyfingIncrementalSales as QualifyingIncrementalSales,
	QualyfingCashback as QualifyingCashback,
	QualyfingOverride as QualifyingOverride,
	TotalSpenders,
	QualyfingSpenders as QualifyingSpenders,
	LengthWeeks,
	ForecastSubmissionDate,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries


END