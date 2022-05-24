
/******************************************************************************
PROCESS NAME: Offer Calculation - Link Offers Across Publishers
PID: OC-003

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Aggregates the output from OC-002 at various levels to provide 
		  incremental metrics.

		  Due to members possibly being on multiple offers at the same time
		  distinct counts (Spenders/Cardholders) need to be calculated.

		  For spenders, this is done by:
			 * Calculating Blended Response Rate for exposed/control = SUM(Spenders) / SUM(Cardholders)
			 * Calculating Blended Response Rate Difference = BlendedRR_Exposed - BlendedRR_Control
			 * Counting DISTINCT Exposed Customers = COUNT(DISTINCT ID) FROM Campaign_History table
			 * Calculating Incremental Spenders = RRDiff * DistinctExposedCustomers
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/

CREATE PROCEDURE [MI].[OfferReport_AggregateOffers] (
    @Monthly bit = 0
)
AS
BEGIN

    SET NOCOUNT ON

    -- Assuming that transactions will be recieved up to 2 weeks after the end of the offer, calculate the month to perform calculation for:
    -- After 2 weeks into the month, assume that the current monthly report (i.e. the previous month) has been completed and start calculating for the next report
	DECLARE @MonthStartDateInt INT
		,	@MonthStartDate DATETIME
	
	IF @Monthly = 1	-- If adjusting adjustments late for Monthly Reports, manually set this to the first of the relevant month
		BEGIN
			EXEC @MonthStartDateInt = [MI].[MonthStartDate_Fetch]
			SET @MonthStartDate = (SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CAST(CONVERT(CHAR(8), @MonthStartDateInt, 112) AS INT))))
		END;

    DECLARE @MonthEndDate date = EOMONTH(@MonthStartDate)

    /*******************************************
    Total Level Aggregation 
	   OfferID IS NULL
	   Channel IS NULL

    *******************************************/
    IF OBJECT_ID('tempdb..#Total') IS NOT NULL DROP TABLE #Total

    -- Clear the current month total metrics
    DELETE FROM MI.OfferReport_Aggregate
    WHERE MonthlyDate = @MonthStartDate

    -- Get retailer level metrics
    SELECT 
	   NULL OfferID
	   , r.MonthlyReportingDate StartDate
	   , EOMONTH(r.MonthlyReportingDate) EndDate
	   , ir.PartnerID
	   , NULL Channel
	   , SUM(r.Sales_E) Sales
	   , SUM(r.IncSales) IncSales
	   , SUM(r.Transactions_E) Transactions
	   , SUM(r.IncTransactions) IncTrans
	   , SUM(r.Spenders_E) Spenders
	   , SUM(r.IncSpenders) IncSpenders
	   , r.MonthlyReportingDate
	   , 0 isCampaign
	   , SUM(r.Cardholders_E) Cardholders_E
	   , SUM(r.Cardholders_C) Cardholders_C
	   , SUM(r.Spenders_C) Spenders_C
	   , NULL BlendedRR_E
	   , NULL BlendedRR_C
	   , NULL UniqueCardholders
    INTO #Total
    FROM Sandbox.Hayden.OfferLinks ol
    JOIN MI.OfferReport_Results r ON r.IronOfferID = ol.IronOfferID
    JOIN Sandbox.Hayden.IronOffer_Refrences ir ON ir.IronOfferID = ol.IronOfferID
    WHERE MonthlyReportingDate = @MonthStartDate
	   AND Channel IS NULL
    GROUP BY ir.PartnerID, MonthlyReportingDate

    -- Calculate blended RR for both Control and Exposed
    
    UPDATE #Total 
    SET BlendedRR_E = Spenders / Cardholders_E
	   , BlendedRR_C = Spenders_C / Cardholders_C

    -- Identify number of unique cardholders for retailer
    UPDATE #Total 
    SET UniqueCardholders = 1 --distinct exposed cardholders per retailer, pull from campaign_history tables or whatever

    -- Calculate incremental Spenders by multiplying Difference in BlendedRR with Distinct Cardholders
    UPDATE #Total 
    SET IncSpenders = (BlendedRR_E - BlendedRR_C) * Cardholders_C -- (Should be UniqueCardholders column)

    INSERT INTO MI.OfferReport_Aggregate 
    SELECT OfferID, StartDate, EndDate, PartnerID, Channel, Sales, IncSales, Transactions, IncTrans, Spenders, IncSpenders, MonthlyReportingDate, isCampaign
    FROM #Total


    /*******************************************
    Channel Level Aggregation 
	   OfferID IS NULL
	   Channel IS NOT NULL

    *******************************************/
    IF OBJECT_ID('tempdb..#Channel') IS NOT NULL DROP TABLE #Channel
    SELECT 
	   NULL OfferID
	   , MonthlyReportingDate StartDate
	   , EOMONTH(MonthlyReportingDate) EndDate
	   , ir.PartnerID
	   , Channel
	   , SUM(r.Sales_E) Sales
	   , SUM(r.IncSales) IncSales
	   , SUM(r.Transactions_E) Transactions
	   , SUM(r.IncTransactions) IncTrans
	   , SUM(r.Spenders_E) Spenders
	   , SUM(r.IncSpenders) IncSpenders
	   , MonthlyReportingDate
	   , 0 isCampaign
	   , SUM(Cardholders_E) Cardholders_E
	   , SUM(Cardholders_C) Cardholders_C
	   , SUM(Spenders_C) Spenders_C
	   , NULL BlendedRR_E
	   , NULL BlendedRR_C
	   , NULL UniqueCardholders
    INTO #Channel
    FROM Sandbox.Hayden.OfferLinks ol
    JOIN MI.OfferReport_Results r ON r.IronOfferID = ol.IronOfferID
    JOIN Sandbox.Hayden.IronOffer_Refrences ir ON ir.IronOfferID = ol.IronOfferID
    WHERE MonthlyReportingDate = @MonthStartDate
	   AND Channel IS NOT NULL
    GROUP BY ir.PartnerID, MonthlyReportingDate, Channel

    UPDATE #Channel 
    SET BlendedRR_E = Spenders / Cardholders_E
	   , BlendedRR_C = Spenders_C / Cardholders_C

    UPDATE #Channel 
    SET UniqueCardholders = 1 --distinct exposed cardholders per retailer, pull from campaign_history tables or whatever

    UPDATE #Channel 
    SET IncSpenders = (BlendedRR_E - BlendedRR_C) * Cardholders_C -- (Should be UniqueCardholders column)

    INSERT INTO MI.OfferReport_Aggregate 
    SELECT OfferID, StartDate, EndDate, PartnerID, Channel, Sales, IncSales, Transactions, IncTrans, Spenders, IncSpenders, MonthlyReportingDate, isCampaign
    FROM #Channel

    /*******************************************
    Offer Level Aggregation 
	   OfferID IS NOT NULL
	   Channel IS NULL

    *******************************************/
    IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer

    SELECT 
	   OfferID
	   , StartDate
	   , EndDate
	   , ir.PartnerID
	   , NULL Channel
	   , SUM(r.Sales_E) Sales
	   , SUM(r.IncSales) IncSales
	   , SUM(r.Transactions_E) Transactions
	   , SUM(r.IncTransactions) IncTrans
	   , SUM(r.Spenders_E) Spenders
	   , SUM(r.IncSpenders) IncSpenders
	   , MonthlyReportingDate
	   , ~isPartial isCampaign
	   , SUM(Cardholders_E) Cardholders_E
	   , SUM(Cardholders_C) Cardholders_C
	   , SUM(Spenders_C) Spenders_C
	   , NULL BlendedRR_E
	   , NULL BlendedRR_C
	   , NULL UniqueCardholders
    INTO #Offer
    FROM Sandbox.Hayden.OfferLinks ol
    JOIN MI.OfferReport_Results r ON r.IronOfferID = ol.IronOfferID
    JOIN Sandbox.Hayden.IronOffer_Refrences ir ON ir.IronOfferID = ol.IronOfferID
    WHERE Channel IS NULL
	   AND NOT EXISTS (
		  SELECT 1 FROM MI.OfferReport_Aggregate a
		  WHERE a.OfferID = ol.OfferID
	   )
    GROUP BY OfferID, StartDate, EndDate, ir.PartnerID, MonthlyReportingDate, Channel, isPartial

    UPDATE #Offer 
    SET BlendedRR_E = Spenders / Cardholders_E
	   , BlendedRR_C = Spenders_C / Cardholders_C

    UPDATE #Offer 
    SET UniqueCardholders = 1 --distinct exposed cardholders per retailer, pull from campaign_history tables or whatever

    UPDATE #Offer 
    SET IncSpenders = (BlendedRR_E - BlendedRR_C) * Cardholders_C -- (Should be UniqueCardholders column)

    INSERT INTO MI.OfferReport_Aggregate 
    SELECT OfferID, StartDate, EndDate, PartnerID, Channel, Sales, IncSales, Transactions, IncTrans, Spenders, IncSpenders, MonthlyReportingDate, isCampaign
    FROM #Offer

END