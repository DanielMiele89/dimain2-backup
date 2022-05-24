-- =============================================
-- Author:		Jason Shipp
-- Create date: 14/07/2017
-- Description: Fetch base and non-base offers and cardholders, live in the current 4-week offer cycle, and populate the MI.Cycle_Live_OffersCardholders, for the Campaign Cycle Live Offers Report
-- =============================================

CREATE PROCEDURE [WHB].[__Redemptions_Cycle_Live_OffersCardholders_Populate_Archived]
	
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	/**************************************************************************
	Declare variables: Current live offer cycle start and end dates
	***************************************************************************/

	DECLARE @Today DATE = CAST(GETDATE() AS DATE);
	DECLARE @CompleteCycles INT = FLOOR((DATEDIFF(day, '2016-12-08', @Today))/28);
	DECLARE @CycleStart DATE = DATEADD(day, @CompleteCycles*28, '2016-12-08');
	DECLARE @CycleEnd DATE = DATEADD(day, 27, @CycleStart);
	
	/**************************************************************************
	Fetch offers from Warehouse and nFI
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Offers') IS NOT NULL 
		DROP TABLE #Offers;

	SELECT *
	INTO #Offers
	FROM (
		SELECT -- Get Iron Offers from Warehouse
			132 AS ClubID
			, io.PartnerID
			, io.IronOfferID
			, io.IronOfferName
			, CAST(io.StartDate AS date) AS StartDate
			, CAST(io.EndDate AS date) AS EndDate
			, pcr.BaseRate AS BaseRate
			, pcr.SpendStretch AS SpendStretch
			, pcr.SpendStretchRate AS SpendStretchRate
			, CASE WHEN base.OfferID IS NOT NULL THEN CAST(1 AS bit) ELSE CAST(0 AS bit) END AS IsBaseOffer
			, camp.ClientServicesRef 
		FROM Derived.IronOffer io
		OUTER APPLY ( -- Get cashback rates
			SELECT 
				MIN(CommissionRate) BaseRate
				, MAX(CommissionRate) SpendStretchRate
				, MAX(MinimumBasketSize) SpendStretch                           
			FROM Derived.IronOffer_PartnerCommissionRule pcr
			WHERE pcr.TypeID = 1
				AND pcr.Status = 1
				AND io.IronOfferID = pcr.IronOfferID
				AND io.PartnerID = pcr.PartnerID
		)pcr
		LEFT JOIN Derived.IronOffer_Campaign_HTM camp
			ON io.IronOfferID = camp.IronOfferID
		LEFT JOIN 
			(SELECT DISTINCT OfferID FROM Derived.PartnerOffers_Base) base
				ON io.IronOfferID = base.OfferID
		WHERE 
			io.IsSignedOff = 1 -- Offers signed off
			AND io.CampaignType <> 'Pre Full Launch Campaign' -- Exclude Pre Full Launch Campaigns, as these are no longer in use
			AND (CAST(io.StartDate AS date) <= @CycleEnd -- Offer overlaps cycle
					AND 
						(CAST(io.EndDate AS date) >= @CycleStart
						OR io.EndDate IS NULL
						)
				)

		UNION ALL

		SELECT -- Get Iron Offers from nFI
			io.ClubID
			, io.PartnerID
			, io.ID AS IronOfferID
			, io.IronOfferName
			, CAST(io.StartDate AS date) AS StartDate
			, CAST(io.EndDate AS date) AS EndDate
			, pcr.BaseRate AS BaseRate
			, pcr.SpendStretch AS SpendStretch
			, pcr.SpendStretchRate AS SpendStretchRate
			, CAST(io.IsAppliedToAllMembers AS bit) AS IsBaseOffer
			, NULL AS ClientServicesRef
		FROM nFI.Relational.IronOffer io
		OUTER APPLY ( -- Get cashback rates
			SELECT 
				MIN(CommissionRate) BaseRate
				, MAX(CommissionRate) SpendStretchRate
				, MAX(MinimumBasketSize) SpendStretch                           
			FROM nFI.Relational.IronOffer_PartnerCommissionRule pcr
			WHERE pcr.TypeID = 1
				AND pcr.Status = 1
				AND io.ID = pcr.IronOfferID
				AND io.PartnerID = pcr.PartnerID
			)pcr
		WHERE 
			io.IsSignedOff = 1 -- Offers signed off
			AND (CAST(io.StartDate AS date) <= @CycleEnd -- Offer overlaps cycle
					AND 
						(CAST(io.EndDate AS date) >= @CycleStart
						OR io.EndDate IS NULL
						)
				)
			) offers;

	CREATE CLUSTERED INDEX CIX_Offers ON #Offers (IronOfferID, isBaseOffer);

	/**************************************************************************
	Fetch members from Warehouse and nFI, applicable for being offer members
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Members') IS NOT NULL 
		DROP TABLE #Members;

	SELECT *
	INTO #Members
	FROM
		(	
		SELECT -- Publisher members in Warehouse 
			c.CompositeID
			, c.FanID
			, 132 AS ClubID
		FROM Derived.Customer c
		WHERE CAST(c.ActivatedDate AS date) <= @CycleStart
			AND (
					CAST(c.DeactivatedDate AS date) >= @CycleStart
					OR c.DeactivatedDate IS NULL
				)

		UNION ALL

		SELECT -- Publisher members in nFI 
			c.CompositeID
			, c.FanID
			, c.ClubID
		FROM nFI.Relational.Customer c
		WHERE
			 CAST(c.RegistrationDate AS date) <= @CycleStart
	) members;

	CREATE CLUSTERED INDEX CIX_ActiveMembers_CompositeID ON #Members (CompositeID); --

	/**************************************************************************
	Filter members to only include cardholders
	***************************************************************************/

	IF OBJECT_ID('tempdb..#Cardholders') IS NOT NULL DROP TABLE #Cardholders;
	SELECT DISTINCT
		m.CompositeID
		, m.FanID
		, m.ClubID
	INTO #Cardholders
	FROM #Members m
	INNER JOIN SLC_Report.dbo.Pan pan
		ON m.CompositeID = pan.CompositeID
		AND (	
				pan.RemovalDate IS NULL -- Card not removed before offer-cycle overlap (card assumed to have already been added as of the day the report is run)
				OR CAST(pan.RemovalDate AS date) >= @CycleStart 
			)
		--AND (
				--pan.DuplicationDate IS NULL -- Card not duplicated before offer-cycle overlap
				--OR CAST(pan.DuplicationDate AS date) >= @CycleStart
			--)
		;

	CREATE CLUSTERED INDEX CIX_Club_Cardholders ON #Cardholders (ClubID);
	CREATE NONCLUSTERED INDEX NIX_Fan_Cardholders ON #Cardholders (FanID);
	CREATE NONCLUSTERED INDEX NIX_Comp_Cardholders ON #Cardholders (CompositeID);

	/**************************************************************************
	Join non-base offers from Warehouse and nFI to cardholders
	***************************************************************************/

	IF OBJECT_ID('tempdb..#NonBaseOfferCardholders') IS NOT NULL DROP TABLE #NonBaseOfferCardholders;
	SELECT *
	INTO #NonBaseOfferCardholders
	FROM (
		SELECT -- Publisher offers in Warehouse
			o.IronOfferID
			, COUNT(DISTINCT(ch.CompositeID)) AS Cardholders 
		FROM #Offers o
 		INNER JOIN Derived.IronOfferMember iom
			ON o.IronOfferID = iom.IronOfferID
		INNER JOIN #Cardholders ch
			ON iom.CompositeID = ch.CompositeID
		WHERE o.IsBaseOffer = 0 -- Non-base offer
		GROUP BY 
			o.IronOfferID

		UNION ALL 

		SELECT -- Publisher offers in nFI
			o.IronOfferID
			, COUNT(DISTINCT(ch.FanID)) AS Cardholders
		FROM #Offers o
		INNER JOIN nFI.Relational.IronOfferMember iom
			ON o.IronOfferID = iom.IronOfferID
		INNER JOIN #Cardholders ch
			ON iom.FanID = ch.FanID
		WHERE o.IsBaseOffer = 0 -- Non-base offer
		GROUP BY 
			o.IronOfferID
	) nonBase;


	-- Join base offers from Warehouse and nFI to cardholders
	IF OBJECT_ID('tempdb..#BaseOfferCardholders') IS NOT NULL DROP TABLE #BaseOfferCardholders;
	SELECT
		o.IronOfferID
		, COUNT(DISTINCT(ch.FanID)) AS Cardholders
	INTO #BaseOfferCardholders
	FROM #Offers o
	INNER JOIN #Cardholders ch
		ON o.ClubID = ch.ClubID 
	WHERE o.IsBaseOffer = 1 -- Base offer
	GROUP BY 
		o.IronOfferID;		


	-- Union results and populate Warehouse.MI.Cycle_Live_OffersCardholders table
	TRUNCATE TABLE Report.Cycle_Live_OffersCardholders;
 	INSERT INTO Report.Cycle_Live_OffersCardholders
		(ReportDate
		, CycleStart
		, CycleEnd
		, ClubID
		, PartnerID
		, IronOfferID
		, IronOfferName
		, OfferStartDate
		, OfferEndDate
		, BaseRate
		, SpendStretch
		, SpendStretchRate
		, IsBaseOffer
		, CampaignCode
		, Cardholders
		)

	SELECT 
	@Today AS ReportDate
	, @CycleStart AS CycleStart
	, @CycleEnd AS CycleEnd
	, o.ClubID
	, o.PartnerID
	, o.IronOfferID
	, o.IronOfferName
	, o.StartDate AS OfferStartDate
	, o.EndDate AS  OfferEndDate
	, o.BaseRate AS BaseRate
	, o.SpendStretch AS SpendStretch
	, o.SpendStretchRate AS SpendStretchRate
	, o.IsBaseOffer
	, o.ClientServicesRef AS CampaignCode
	, x.Cardholders	
	FROM
		(SELECT * FROM #NonBaseOfferCardholders
		UNION ALL 
		SELECT * FROM #BaseOfferCardholders
		) x
	INNER JOIN #Offers o
		ON x.IronOfferID = o.IronOfferID;


	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END