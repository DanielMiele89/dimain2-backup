
/***********************************************************************

	Author:		 Hayden Reid
	Create date: 25/10/2016
	Description: Gets the IronOfferIDs that are to be reported on in the Threshold report.

	This fetch is used in an SSIS package to pull the results to the AllPublisherWarehouse so that
	it can be used to query SchemeTrans

	======================= Change Log =======================

***********************************************************************/


CREATE PROCEDURE [MI].[ThresholdReport_Fetch_IronOfferIDs] 
AS
BEGIN

    /**************************************************************************
	   Use Cycle dates to identify the most recent cycle that completed 2 weeks prior

	   How it works:
		  - Find the difference between the cycle start and today's date
		  - Divide this by the number of days in the cycle + 1 week 
			 - This gives the number of cycles there are between the Cycle Start/End and Today + a week to
			 account for 2 week gap needed to get transactions
		  Example:
			 4 Week Cycle:
				4 week cycle + 1 week = 5 * 7 days = 35 days
			 32 Day Cycle: 
				32 day cycle + 7 days = 39 days
		  - Multiply this by the number of weeks or days in a cycle
		  - Add this number of days or weeks to the Cycle Start/End
		  - This will return the closest cycle Start/End Dates that finished at least 2 weeks prior

	   Worked Example:
		  Current = 4 Week/28 Day cycle:
			 DECLARE @StartDate DATE = DATEADD(WEEK, (DATEDIFF(DAY, @CycleStart, @CurrDate)/35)*28, @CycleStart)
			 DECLARE @EndDate Date = DATEADD(WEEK, (DATEDIFF(DAY, @CycleStart, @CurrDate)/35)*28, @CycleEnd)    
    
		  Modify = 6 Week/42 Day cycle:
		      DECLARE @StartDate DATE = DATEADD(WEEK, (DATEDIFF(DAY, @CycleStart, @CurrDate)/49)*42, @CycleStart)
			 DECLARE @EndDate Date = DATEADD(WEEK, (DATEDIFF(DAY, @CycleStart, @CurrDate)/49)*42, @CycleEnd)    

		  Modify = 32 Day cycle - Change DATEADD from WEEK to DAY:
		      DECLARE @StartDate DATE = DATEADD(DAY, (DATEDIFF(DAY, @CycleStart, @CurrDate)/39)*32, @CycleStart)
			 DECLARE @EndDate Date = DATEADD(DAY, (DATEDIFF(DAY, @CycleStart, @CurrDate)/39)*32, @CycleEnd)    

	   -- HR
    **************************************************************************/
    -- SET a cycles start and end date (doesn't matter what the dates are as long as they are representative of a cycle)
    DECLARE @CycleStart DATE = '2016-04-28'
    DECLARE @CycleEnd DATE = '2016-05-25'
    DECLARE @Lag INT = 14 -- Minimum number of days the Cycle needs to have finished for

    -- Sets variables to calculate Cycle
    DECLARE @DayDiff INT = DATEDIFF(DAY, @CycleStart, @CycleEnd) + (@Lag/2) + 1
    DECLARE @WeekDiff INT = DATEDIFF(WEEK, @CycleStart, @CycleEnd) * 7   
    DECLARE @CurrDate DATE = GETDATE()

    -- Use Cycle Dates and Current Date to calculate what the current cycle dates are
    DECLARE @StartDate DATE = DATEADD(DAY, (ROUND(1.0*DATEDIFF(DAY, @CycleStart, @CurrDate)/@DayDiff, 0))*@WeekDiff, @CycleStart)
    DECLARE @EndDate Date = DATEADD(DAY, (ROUND(1.0*DATEDIFF(DAY, @CycleStart, @CurrDate)/@DayDiff, 0))*@WeekDiff, @CycleEnd)

    ---- Manual dates
    --SET @StartDate = '2016-10-13'
    --SET @EndDate = '2016-11-09'

    -- Get all the offers that are related for this cycle period
    SELECT DISTINCT
	   p.PartnerID
	   , p.PartnerName
	   , IronOfferID
	   , RIGHT(IronOfferName, ISNULL(NULLIF(CHARINDEX('/', REVERSE(IronOfferName))-1, -1), 999)) IronOfferName
	   , @StartDate StartDate
	   , @EndDate EndDate
    FROM (

	   SELECT
		  io.PartnerID
		  , io.IronOfferName
		  , io.IronOfferID
	   FROM Warehouse.Relational.IronOffer_References ir
	   JOIN Warehouse.Relational.IronOffer io on io.IronOfferID = ir.IronOfferID
	   JOIN Warehouse.Relational.ironoffercycles ioc on ioc.IronOfferID = io.IronOfferID
	   JOIN Warehouse.Relational.OfferCycles oc on oc.OfferCyclesID = ioc.offercyclesid
	   WHERE PartnerID in (4552)
		  AND CAST(oc.StartDate as DATE) = @StartDate
		  AND CAST(oc.EndDate as DATE)= @EndDate
	   
	   UNION ALL

	   SELECT
		  io.PartnerID
		  , io.IronOfferName
		  , io.ID
	   FROM nfi.Relational.IronOffer_References ir
	   JOIN nfi.Relational.IronOffer io on io.ID = ir.IronOfferID
	   JOIN nfi.Relational.ironoffercycles ioc on ioc.IronOfferID = io.ID
	   JOIN nfi.Relational.OfferCycles oc on oc.OfferCyclesID = ioc.offercyclesid
	   WHERE PartnerID in (4552)
		  AND CAST(oc.StartDate as DATE) = @StartDate
		  AND CAST(oc.EndDate as DATE)= @EndDate
	   

	   --SELECT
		  --PartnerID
		  --, IronOfferName
		  --, IronOfferID
	   --FROM Relational.IronOffer
	   --WHERE PartnerID in (4552) -- ASK Italian
		  --AND (StartDate <= @EndDate AND COALESCE(EndDate, GETDATE()) >= @StartDate)

	   --UNION ALL

	   --SELECT
		  --PartnerID
		  --, IronOfferName
		  --, ID
	   --FROM nfi.Relational.IronOffer
	   --WHERE PartnerID in (4552) -- ASK Italian
		  --AND (StartDate <= @EndDate AND COALESCE(EndDate, GETDATE()) >= @StartDate)
    ) x
    JOIN Warehouse.Relational.Partner p on p.PartnerID = x.PartnerID

END


