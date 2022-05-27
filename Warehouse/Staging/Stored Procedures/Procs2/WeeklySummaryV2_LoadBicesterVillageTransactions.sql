/******************************************************************************
Author: Rory Francis
Created: 2021-12-20
Purpose: 
	- Load the transaction counsts for the Bicester Village offer
-------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Staging].[WeeklySummaryV2_LoadBicesterVillageTransactions]
AS
BEGIN

		;WITH
		RetailerAnalysisPeriods AS (SELECT	rap.PeriodType
										,	rap.StartDate
										,	rap.EndDate
									FROM [Staging].[WeeklySummaryV2_RetailerAnalysisPeriods] rap
									WHERE rap.RetailerID = 4938)
	   

	--	Grouping: Retailer
	
		SELECT	iof.RetailerID
			,	PublisherID = NULL
			,	OfferTypeForReports = NULL
			,	PeriodType = rap.PeriodType
			,	StartDate = rap.StartDate
			,	EndDate = rap.EndDate
			,	Spenders = COUNT(DISTINCT ts.FanID)
			,	Transactions = COUNT(*)
			,	Sales = SUM(ts.Amount)
			,	Grouping = 'Retailer'
			,	ReportDate = CONVERT(DATE, GETDATE())
		FROM [SLC_REPL].[dbo].[CBP_RetailerGroup_TransactionStore] ts
		INNER JOIN RetailerAnalysisPeriods rap
			ON CONVERT(DATE, ts.TranDate) BETWEEN rap.StartDate AND rap.EndDate
		LEFT JOIN [WH_AllPublishers].[Derived].[Offer] iof
			ON ts.IronOfferID = iof.IronOfferID
		WHERE ts.TranStatus = 1
		GROUP BY	iof.RetailerID
				,	rap.PeriodType
				,	rap.StartDate
				,	rap.EndDate

		UNION ALL

	--	Grouping: RetailerOfferType

		SELECT	iof.RetailerID
			,	PublisherID = NULL
			,	OfferTypeForReports =	CASE
											WHEN iof.SegmentID = 7 THEN 'Acquisition'
											WHEN iof.SegmentID = 8 THEN 'Lapsed'
											WHEN iof.SegmentID = 9 THEN 'Shopper'
											ELSE 'Universal'
										END
			,	PeriodType = rap.PeriodType
			,	StartDate = rap.StartDate
			,	EndDate = rap.EndDate
			,	Spenders = COUNT(DISTINCT ts.FanID)
			,	Transactions = COUNT(*)
			,	Sales = SUM(ts.Amount)
			,	Grouping = 'RetailerOfferType'
			,	ReportDate = CONVERT(DATE, GETDATE())
		FROM [SLC_REPL].[dbo].[CBP_RetailerGroup_TransactionStore] ts
		INNER JOIN RetailerAnalysisPeriods rap
			ON CONVERT(DATE, ts.TranDate) BETWEEN rap.StartDate AND rap.EndDate
		LEFT JOIN [WH_AllPublishers].[Derived].[Offer] iof
			ON ts.IronOfferID = iof.IronOfferID
		WHERE ts.TranStatus = 1
		GROUP BY	iof.RetailerID
				,	CASE
						WHEN iof.SegmentID = 7 THEN 'Acquisition'
						WHEN iof.SegmentID = 8 THEN 'Lapsed'
						WHEN iof.SegmentID = 9 THEN 'Shopper'
						ELSE 'Universal'
					END
				,	rap.PeriodType
				,	rap.StartDate
				,	rap.EndDate

		UNION ALL

	--	Grouping: RetailerPublisher

		SELECT	iof.RetailerID
			,	PublisherID = iof.PublisherID
			,	OfferTypeForReports = NULL
			,	PeriodType = rap.PeriodType
			,	StartDate = rap.StartDate
			,	EndDate = rap.EndDate
			,	Spenders = COUNT(DISTINCT ts.FanID)
			,	Transactions = COUNT(*)
			,	Sales = SUM(ts.Amount)
			,	Grouping = 'RetailerPublisher'
			,	ReportDate = CONVERT(DATE, GETDATE())
		FROM [SLC_REPL].[dbo].[CBP_RetailerGroup_TransactionStore] ts
		INNER JOIN RetailerAnalysisPeriods rap
			ON CONVERT(DATE, ts.TranDate) BETWEEN rap.StartDate AND rap.EndDate
		LEFT JOIN [WH_AllPublishers].[Derived].[Offer] iof
			ON ts.IronOfferID = iof.IronOfferID
		WHERE ts.TranStatus = 1
		GROUP BY	iof.RetailerID
				,	iof.PublisherID
				,	rap.PeriodType
				,	rap.StartDate
				,	rap.EndDate

END