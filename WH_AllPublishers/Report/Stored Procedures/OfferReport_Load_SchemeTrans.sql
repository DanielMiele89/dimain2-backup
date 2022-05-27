/******************************************************************************
PROCESS NAME: Offer Calculation - Calculate Performance - Fetch CT Metrics

Author		Rory Francis
Created		12/01/2021
Purpose		Stores subset of the transactions required for processing

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Load_SchemeTrans]

AS
BEGIN

		IF OBJECT_ID('tempdb..#RetailerDetails') IS NOT NULL DROP TABLE #RetailerDetails;
		SELECT	o.PublisherType
			,	o.PublisherID
			,	pa.RetailerName
			,	pa.PartnerID
			,	pa.RetailerID
			,	ao.OfferID
			,	ao.IronOfferID
			,	ao.OfferReportingPeriodsID
			,	ao.ControlGroupID
			,	ao.IsInPromgrammeControlGroup
			,	ao.StartDate
			,	ao.EndDate
		INTO #RetailerDetails
		FROM [Report].[OfferReport_AllOffers] ao
		LEFT JOIN [Derived].[Offer] o
			ON ao.OfferID = o.OfferID
		INNER JOIN [Derived].[Partner] pa
			ON ao.PartnerID = pa.PartnerID
		WHERE o.PublisherType = 'Card Scheme'
		ORDER BY	o.PublisherType

		DECLARE @StartDate DATETIME
			,	@EndDate DATETIME

		SELECT	@StartDate = MIN(StartDate)
			,	@EndDate = MAX(EndDate)
		FROM [Report].[OfferReport_AllOffers]

		TRUNCATE TABLE [Report].[OfferReport_SchemeTrans]

		INSERT INTO [Report].[OfferReport_SchemeTrans]
		SELECT	DateSource = 'Card Scheme'
			,	RetailerID = rd.RetailerID
			,	PartnerID = rd.PartnerID
			,	MID = '0'
			,	FanID = st.FanID
			,	CINID = CONVERT(INT, NULL)
			,	IsOnline = st.IsOnline
			,	Amount = st.Spend
			,	TranDate = st.TranDate
			,	MatchID = st.ID
		FROM [Derived].[SchemeTrans] st
		INNER JOIN #RetailerDetails rd
			ON st.IronOfferID = rd.IronOfferID
			AND 0 < st.Spend
			AND st.IsRetailerReport = 1
		WHERE st.TranDate BETWEEN @StartDate AND @EndDate
					
	--CREATE CLUSTERED INDEX CIX_MatchID ON [Report].[OfferReport_MatchTrans] (MatchID)
	--CREATE NONCLUSTERED INDEX IX_FanID ON [Report].[OfferReport_MatchTrans] (FanID)
	--CREATE NONCLUSTERED INDEX IX_PartnerIDTrandDateAmount ON [Report].[OfferReport_MatchTrans] (PartnerID,[TranDate],[Amount]) INCLUDE (IsOnline)

END



