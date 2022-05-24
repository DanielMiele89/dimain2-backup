
/******************************************************************************
PROCESS NAME: Offer Calculation - Insert Ready Offers
PID: OC-001

Author	  Hayden Reid
Created	  23/09/2016
Purpose	  Gets the offers for Offer and Monthly reporting that were live 
		  and are also available for reporting.

		  Live - An offer that was running at any part during the reporting month
			 (only applicable to Monthly reports)
		  Available - An offer that ended after a specified time (2 weeks)
			 For monthly reporting this is the end of the offer or if this
			 falls outside of the month, 2 weeks at the end of the reporting month
	  
Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/


CREATE PROCEDURE [MI].[OfferReport_Insert_ReadyOffers] 
AS
BEGIN

    SET NOCOUNT ON

    -- Assuming that transactions will be recieved up to 2 weeks after the end of the offer, calculate the month to perform calculation for:
    -- After 2 weeks into the month, assume that the current monthly report (i.e. the previous month) has been completed and start calculating for the next report
	DECLARE @MonthStartDateInt INT
		,	@MonthStartDate DATETIME
	
	EXEC @MonthStartDateInt = [BI].[MonthStartDate_Fetch]
	SET @MonthStartDate = (SELECT CONVERT(DATETIME, CONVERT(CHAR(8), CAST(CONVERT(CHAR(8), @MonthStartDateInt, 112) AS INT))));

    DECLARE @MonthEndDate date = EOMONTH(@MonthStartDate)

    TRUNCATE TABLE MI.OfferReport_Staging_AllOffers

    -- Get available full offers that do not have a row in the results table i.e. have not been calculated yet
    INSERT INTO MI.OfferReport_Staging_AllOffers (IronOfferID, StartDate, EndDate, PartnerID, PublisherID, CashbackRate, SpendStretch, isPartial)
    SELECT DISTINCT
	   ior.IronOfferID
	   , cy.StartDate
	   , cy.EndDate
	   , ior.PartnerID
	   , ior.ClubID
	   , ior.CashbackRate
	   , ior.SpendStretch
	   , 0 isPartial
    FROM Sandbox.Hayden.IronOffer_Refrences ior
    JOIN Sandbox.Hayden.Cycles cy on cy.CycleID = ior.CycleID
    WHERE NOT EXISTS (
	   SELECT 1 FROM MI.OfferReport_Results o
	   WHERE o.IronOfferID = ior.IronOfferID
		  and o.StartDate = cy.StartDate and o.EndDate = o.EndDate and o.isPartial = 0
    ) 
	   and cy.EndDate <= GETDATE()-13 -- All offers that have ended 2 weeks prior


    -- Get all offers that are partial and not been calculated
    INSERT INTO MI.OfferReport_Staging_AllOffers (IronOfferID, StartDate, EndDate, PartnerID, PublisherID, CashbackRate, SpendStretch, isPartial)
    SELECT DISTINCT
	   ior.IronOfferID
	   , CASE WHEN cy.StartDate < @MonthStartDate THEN @MonthStartDate ELSE cy.StartDate END -- Set Start Date to be month boundary or start date (whichever is latest)
	   , CASE WHEN cy.EndDate > @MonthEndDate THEN @MonthEndDate ELSE cy.EndDate END -- Set End Date to be month boundary or end date (whichever is earliest)
	   , ior.PartnerID
	   , ior.ClubID
	   , ior.CashbackRate -- Ask Stuart
	   , ior.SpendStretch
	   , 1 isPartial
    FROM Sandbox.Hayden.IronOffer_Refrences ior
    JOIN Sandbox.Hayden.Cycles cy on cy.CycleID = ior.CycleID
    WHERE NOT EXISTS (
	   SELECT 1 FROM MI.OfferReport_Results o
	   WHERE o.IronOfferID = ior.IronOfferID
		  and o.StartDate = CASE WHEN cy.StartDate < @MonthStartDate THEN @MonthStartDate ELSE cy.StartDate END 
		  and o.EndDate = CASE WHEN cy.EndDate > @MonthEndDate THEN @MonthEndDate ELSE cy.EndDate END
		  and o.isPartial = 1
    ) 
	   and (@MonthStartDate between cy.StartDate and cy.EndDate or @MonthEndDate between cy.StartDate and cy.EndDate) -- All campaigns that are live in the month
	   and (cy.Startdate < @MonthStartDate or cy.EndDate > @MonthEndDate) -- and fall outside of the month boundaries
	   and (CASE WHEN cy.EndDate > @MonthEndDate THEN @MonthEndDate ELSE cy.EndDate END <= GETDATE()-13) -- And the end of the offer or End of Month is 2 weeks prior


    -- Calculate which offers are able to be used in a monthly report and mark with the start of the reporting month
    UPDATE MI.OfferReport_Staging_AllOffers
    SET ReportingDate = @MonthStartDate
    WHERE StartDate between @MonthStartDate and @MonthEndDate
	   and EndDate between @MonthStartDate and @MonthEndDate

    -- Insert offers into log table to be picked up for calculation
    INSERT INTO MI.OfferReport_Log (IronOfferID, StartDate, EndDate, isPartial, MonthlyReportingDate)
    SELECT DISTINCT IronOfferID, StartDate, EndDate, isPartial, ReportingDate 
    FROM MI.OfferReport_Staging_AllOffers

END