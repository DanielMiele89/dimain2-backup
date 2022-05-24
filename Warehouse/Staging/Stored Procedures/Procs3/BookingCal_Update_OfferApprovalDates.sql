

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 29/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_Offers
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_OfferApprovalDates]
									
AS
BEGIN
	SET NOCOUNT ON;


/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bco.CalendarYear,
	bco.ClientServicesRef,
	bco.DateForecastExpected,
	bco.DateBriefSubmitted,
	bco.ApprovedByRetailer,
	bco.ApprovedByRBSG
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_Offers bco
LEFT OUTER JOIN Warehouse.Relational.BookingCal_OfferApprovalDates bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
	AND ISNULL(bco.DateForecastExpected,'1901-01-01') = ISNULL(bco2.DateForecastExpected,'1901-01-01')
	AND ISNULL(bco.DateBriefSubmitted,'1901-01-01') = ISNULL(bco2.DateBriefSubmitted,'1901-01-01')
	AND bco.ApprovedByRetailer = bco2.ApprovedByRetailer
	AND bco.ApprovedByRBSG = bco2.ApprovedByRBSG
WHERE	bco2.ClientServicesRef IS NULL 


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bco.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_OfferApprovalDates bco
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_Offers bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
WHERE	bco2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferApprovalDates
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferApprovalDates bco
INNER JOIN #NewEntries ne
	ON bco.CalendarYear = ne.CalendarYear
	AND bco.ClientServicesRef = ne.ClientServicesRef
WHERE bco.Status_EndDate IS NULL


/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferApprovalDates
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferApprovalDates bco
INNER JOIN #DeletedEntries de
	ON bco.CalendarYear = de.CalendarYear
	AND bco.ClientServicesRef = de.ClientServicesRef
WHERE bco.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_OfferApprovalDates
SELECT	CalendarYear,
	ClientServicesRef,
	DateForecastExpected,
	DateBriefSubmitted,
	ApprovedByRetailer,
	ApprovedByRBSG,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries



END