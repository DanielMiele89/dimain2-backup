

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 23/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_CustomerSelection
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_CustomerSelection]
									
AS
BEGIN
	SET NOCOUNT ON;


/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bcs.*
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_CustomerSelection bcs
LEFT OUTER JOIN Warehouse.Relational.BookingCal_CustomerSelection bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
	AND bcs.ForecastSubmissionDate = bcs2.ForecastSubmissionDate
	AND bcs.StartDate = bcs2.Campaign_StartDate
	AND bcs.EndDate = bcs2.Campaign_EndDate
	AND ISNULL(bcs.SegmentID,0) = ISNULL(bcs2.SegmentID,0)
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bcs.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_CustomerSelection bcs
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_CustomerSelection bcs2
	ON bcs.ClientServicesRef = bcs2.ClientServicesRef
	AND bcs.ForecastSubmissionDate = bcs2.ForecastSubmissionDate
	AND bcs.Campaign_StartDate = bcs2.StartDate
	AND bcs.Campaign_EndDate = bcs2.EndDate
	AND ISNULL(bcs.SegmentID,0) = ISNULL(bcs2.SegmentID,0)
WHERE bcs2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_CustomerSelection
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_CustomerSelection bcs
INNER JOIN #NewEntries ne
	ON bcs.ClientServicesRef = ne.ClientServicesRef
	AND bcs.Campaign_StartDate = ne.StartDate
	AND bcs.Campaign_EndDate = ne.EndDate
	AND ISNULL(bcs.SegmentID,0) = ISNULL(ne.SegmentID,0)
WHERE bcs.Status_EndDate IS NULL



/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_CustomerSelection
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_CustomerSelection bcs
INNER JOIN #DeletedEntries de
	ON bcs.ClientServicesRef = de.ClientServicesRef
	AND bcs.Campaign_StartDate = de.Campaign_StartDate
	AND bcs.Campaign_EndDate = de.Campaign_EndDate
	AND ISNULL(bcs.SegmentID,0) = ISNULL(de.SegmentID,0)
WHERE bcs.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_CustomerSelection
SELECT	ClientServicesRef,
	StartDate as Campaign_StartDate,
	EndDate as Campaign_EndDate,
	SegmentID,
	Gender,
	MinAge,
	MaxAge,
	DriveTimeBand,
	CAMEO_CODE_GRP,
	SocialClass,
	MinHeatMapScore,
	MaxHeatMapScore,
	BespokeTargeting,
	QualifyingMids,
	TargetedVolume,
	ControlVolume,
	TotalSpenders,
	QualyfingSpenders as QualifyingSpenders,
	TotalIncrementalSpenders,
	TotalSales,
	QualifyingSales,
	TotalIncrementalSales,
	ForecastSubmissionDate,
	RetailerType,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries



END