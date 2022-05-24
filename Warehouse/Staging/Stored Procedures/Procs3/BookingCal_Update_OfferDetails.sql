

-- ******************************************************************************
-- Author: Suraj Chahal
-- Create date: 29/09/2015
-- Description: Runs Daily and Updates Relational.BookingCal_Offers
--		with latest data in ExcelQuery
-- ******************************************************************************
CREATE PROCEDURE [Staging].[BookingCal_Update_OfferDetails]
									
AS
BEGIN
	SET NOCOUNT ON;


/***************************************************
*******************Find New Entries*****************
***************************************************/
IF OBJECT_ID ('tempdb..#NewEntries') IS NOT NULL DROP TABLE #NewEntries
SELECT	bco.CalendarYear,
	bco.ClientServicesRef,
	bco.CampaignName,
	bco.CampaignType,
	bco.PartnerID,
	bco.BrandID,
	bco.MinOfferRate,
	bco.MaxOfferRate,
	bco.MinSS,
	bco.MaxSS,
	bco.StartDate,
	bco.Enddate
INTO #NewEntries
FROM Warehouse.ExcelQuery.BookingCal_Offers bco
LEFT OUTER JOIN Warehouse.Relational.BookingCal_OfferDetails bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
	AND ISNULL(bco.CampaignName,0) = ISNULL(bco2.CampaignName,0)
	AND ISNULL(bco.CampaignType,0) = ISNULL(bco2.CampaignType,0)
	AND ISNULL(bco.PartnerID,0) = ISNULL(bco2.PartnerID,0)
	AND ISNULL(bco.BrandID,0) = ISNULL(bco2.BrandID,0)
	AND ISNULL(bco.MinOfferRate,0) = ISNULL(bco2.MinOfferRate,0)
	AND ISNULL(bco.MaxOfferRate,0) = ISNULL(bco2.MaxOfferRate,0)
	AND ISNULL(bco.MinSS,0) = ISNULL(bco2.MinSS,0)
	AND ISNULL(bco.MaxSS,0) = ISNULL(bco2.MaxSS,0)
	AND ISNULL(bco.StartDate,'1901-01-01') = ISNULL(bco2.Campaign_StartDate,'1901-01-01')
	AND ISNULL(bco.Enddate,'1901-01-01') = ISNULL(bco2.Campaign_Enddate,'1901-01-01')
WHERE bco2.ClientServicesRef IS NULL


/****************************************************************************
*********Find Entries which have been deleted from Booking Calendar**********
****************************************************************************/
IF OBJECT_ID ('tempdb..#DeletedEntries') IS NOT NULL DROP TABLE #DeletedEntries
SELECT	bco.*
INTO #DeletedEntries
FROM Warehouse.Relational.BookingCal_OfferDetails bco
LEFT OUTER JOIN Warehouse.ExcelQuery.BookingCal_Offers bco2
	ON bco.CalendarYear = bco2.CalendarYear
	AND bco.ClientServicesRef = bco2.ClientServicesRef
WHERE	bco2.ClientServicesRef IS NULL


/****************************************************************
*****************Add EndDate to Changed entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferDetails
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferDetails bco
INNER JOIN #NewEntries ne
	ON bco.CalendarYear = ne.CalendarYear
	AND bco.ClientServicesRef = ne.ClientServicesRef
 	AND ISNULL(bco.CampaignName,0) = ISNULL(ne.CampaignName,0)
	AND ISNULL(bco.CampaignType,0) = ISNULL(ne.CampaignType,0)
	AND ISNULL(bco.PartnerID,0) = ISNULL(ne.PartnerID,0)
	AND ISNULL(bco.BrandID,0) = ISNULL(ne.BrandID,0)
	AND ISNULL(bco.MinOfferRate,0) = ISNULL(ne.MinOfferRate,0)
	AND ISNULL(bco.MaxOfferRate,0) = ISNULL(ne.MaxOfferRate,0)
	AND ISNULL(bco.MinSS,0) = ISNULL(ne.MinSS,0)
	AND ISNULL(bco.MaxSS,0) = ISNULL(ne.MaxSS,0)
	AND ISNULL(bco.Campaign_StartDate,'1901-01-01') = ISNULL(ne.StartDate,'1901-01-01')
	AND ISNULL(bco.Campaign_Enddate,'1901-01-01') = ISNULL(ne.Enddate,'1901-01-01')
WHERE bco.Status_EndDate IS NULL


/****************************************************************
*****************Add EndDate to Deleted entries******************
****************************************************************/
--**For records where there are Updates, we must EndDate the
--**previous ones
UPDATE Warehouse.Relational.BookingCal_OfferDetails
SET Status_EndDate = DATEADD(DAY,-1,CAST(GETDATE() AS DATE))
FROM Warehouse.Relational.BookingCal_OfferDetails bco
INNER JOIN #DeletedEntries de
	ON bco.CalendarYear = de.CalendarYear
	AND bco.ClientServicesRef = de.ClientServicesRef
WHERE bco.Status_EndDate IS NULL


/****************************************************************
************Insert New Entries With NULL as EndDate**************
****************************************************************/
INSERT INTO Warehouse.Relational.BookingCal_OfferDetails
SELECT	CalendarYear,
	ClientServicesRef,
	CampaignName,
	CampaignType,
	PartnerID,
	BrandID,
	MinOfferRate,
	MaxOfferRate,
	MinSS,
	MaxSS,
	StartDate as Campaign_StartDate,
	Enddate as Campaign_EndDate,
	CAST(GETDATE() AS DATE) as Status_StartDate,
	CAST(NULL AS DATE) as Status_EndDate
FROM #NewEntries



END