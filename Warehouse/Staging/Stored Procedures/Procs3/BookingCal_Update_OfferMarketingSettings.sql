

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 30/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_Offers
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_OfferMarketingSettings]
									
AS
BEGIN
	SET NOCOUNT ON;

/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bco.CalendarYear,
	bco.ClientServicesRef,
	bco.MarketingSupport,
	bco.EmailTesting,
	bco.ATL
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_Offers bco
LEFT OUTER JOIN Warehouse.Relational.BookingCal_OfferMarketingSettings bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
	AND bco.MarketingSupport = bco2.MarketingSupport
	AND bco.EmailTesting = bco2.EmailTesting
	AND bco.ATL = bco2.ATL
WHERE	bco2.ClientServicesRef IS NULL 


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bco.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_OfferMarketingSettings bco
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_Offers bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
WHERE	bco2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferMarketingSettings
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferMarketingSettings bco
INNER JOIN #NewEntries ne
	ON bco.CalendarYear = ne.CalendarYear
	AND bco.ClientServicesRef = ne.ClientServicesRef
WHERE bco.Status_EndDate IS NULL


/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferMarketingSettings
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferMarketingSettings bco
INNER JOIN #DeletedEntries de
	ON bco.CalendarYear = de.CalendarYear
	AND bco.ClientServicesRef = de.ClientServicesRef
WHERE bco.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_OfferMarketingSettings
SELECT	CalendarYear,
	ClientServicesRef,
	MarketingSupport,
	EmailTesting,
	ATL,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries



END