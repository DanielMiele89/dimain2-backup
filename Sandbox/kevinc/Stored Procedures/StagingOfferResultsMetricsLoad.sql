CREATE PROC [kevinc].[StagingOfferResultsMetricsLoad]
AS

	--IF OBJECT_ID('kevinc.StagingOfferResultsMetrics') IS NOT NULL
	--DROP TABLE kevinc.StagingOfferResultsMetrics;
	--CREATE TABLE kevinc.StagingOfferResultsMetrics(
	--		ReportingOfferID				INT NOT NULL,
	--		StartDate						DATETIME2(7) NOT NULL,
	--		EndDate							DATETIME2(7) NOT NULL,
	--		Sales_E							MONEY NULL,
	--		CardHolders_E					INT NULL,
	--		Spenders_E						INT NULL,
	--		SpendPerCardHolder_E			MONEY NULL,
	--		TransactionsPerCardHolder_E		DECIMAL(18,2) NULL,
	--		RR_E							DECIMAL(18,2) NULL,
	--		AverageTransactionValue_E		MONEY NULL,
	--		AverageTransactionFrequency_E	DECIMAL(18,2) NULL,
	--		SpendPerSpender_E				MONEY NULL,
	--		Sales_C							MONEY NULL,
	--		CardHolders_C					INT NULL,
	--		Spenders_C						INT NULL,
	--		SpendPerCardHolder_C			MONEY NULL,
	--		TransactionsPerCardHolder_C		DECIMAL(18,2) NULL,
	--		RR_C							DECIMAL NULL,
	--		AverageTransactionValue_C		MONEY NULL,
	--		AverageTransactionFrequency_C	DECIMAL(18,2) NULL,
	--		SpendPerSpender_C				MONEY NULL,
	--		Uplift							DECIMAL(18,2)	NULL,
	--)
	--CREATE CLUSTERED INDEX CIX ON kevinc.StagingOfferResultsMetrics(ReportingOfferID)

	;WITH ExposedGroupMetrics AS (
		SELECT	
				EGM.ReportingOfferID,
				EGM.Amount AS Sales,
				(EGM.Amount / EGM.CardHolders) AS SpendPerCardHolder,
				CAST((CAST(EGM.TransactionCount AS DECIMAL(15,4)) / CAST(EGM.CardHolders AS DECIMAL(15,4))) AS DECIMAL(6,2)) AS TransactionsPerCardHolder,
				(CAST(DistinctSpenders/EGM.CardHolders AS NUMERIC(16,4)) * 100) AS ResponseRate, 
				(EGM.Amount / EGM.TransactionCount) AS AverageTransactionValue,
				(EGM.TransactionCount/EGM.DistinctSpenders) AS AverageTransactionFrequency, 
				(EGM.Amount / EGM.DistinctSpenders) AS SpendPerSpender,
				EGM.CardHolders AS CardHolders,
				EGM.DistinctSpenders AS Spenders
		FROM kevinc.StagingExposedGroupMetrics EGM
	)
	, ControlGroupMetrics AS (
		SELECT 
				CGM.ReportingOfferID, 
				CGM.Amount AS Sales,
				(CGM.Amount / CGM.CardHolders) AS SpendPerCardHolder,
				CAST((CAST(CGM.TransactionCount AS DECIMAL(15,4)) / CAST(CGM.CardHolders AS DECIMAL(15,4))) AS DECIMAL(6,2)) AS TransactionsPerCardHolder,
				CAST(DistinctSpenders/CGM.CardHolders AS NUMERIC(16,4)) AS ResponseRate, 
				(CGM.Amount / CGM.TransactionCount) AS AverageTransactionValue,
				(CGM.TransactionCount/CGM.DistinctSpenders) AS AverageTransactionFrequency, 
				(CGM.Amount / CGM.DistinctSpenders) AS SpendPerSpender,
				CGM.CardHolders AS CardHolders,
				CGM.DistinctSpenders AS Spenders
		FROM kevinc.StagingControlGroupMetrics CGM
	)
	INSERT INTO [kevinc].[StagingOfferResultsMetrics]([ReportingOfferID], [StartDate], [EndDate], [Sales_E], [CardHolders_E], [Spenders_E], [SpendPerCardHolder_E], [TransactionsPerCardHolder_E], [RR_E], [AverageTransactionValue_E], [AverageTransactionFrequency_E], [SpendPerSpender_E], [Sales_C], [CardHolders_C], [Spenders_C], [SpendPerCardHolder_C], [TransactionsPerCardHolder_C], [RR_C], [AverageTransactionValue_C], [AverageTransactionFrequency_C], [SpendPerSpender_C], [Uplift]) 
	SELECT
		O.ReportingOfferID, 
		O.StartDate, 
		O.EndDate, 
		EGM.Sales						AS Sales_E,
		EGM.CardHolders					AS CardHolders_E,
		EGM.Spenders					AS Spenders_E,
		EGM.SpendPerCardHolder			AS SpendPerCardHolder_E,
		EGM.TransactionsPerCardHolder	AS TransactionsPerCardHolder_E,
		EGM.ResponseRate				AS RR_E,
		EGM.AverageTransactionValue		AS AverageTransactionValue_E,
		EGM.AverageTransactionFrequency AS AverageTransactionFrequency_E,
		EGM.SpendPerSpender				AS SpendPerSpender_E,
		CGM.Sales						AS Sales_C,
		CGM.CardHolders					AS CardHolders_C,
		CGM.Spenders					AS Spenders_E,
		CGM.SpendPerCardHolder			AS SpendPerCardHolder_C,
		CGM.TransactionsPerCardHolder	AS TransactionsPerCardHolder_C,
		CGM.ResponseRate				AS RR_C,
		CGM.AverageTransactionValue		AS AverageTransactionValue_C,
		CGM.AverageTransactionFrequency AS AverageTransactionFrequency_C,
		CGM.SpendPerSpender				AS SpendPerSpender_C,
		(EGM.SpendPerCardHolder - CGM.SpendPerCardHolder) / CGM.SpendPerCardHolder AS [Uplift]
	FROM ExposedGroupMetrics EGM
	LEFT JOIN ControlGroupMetrics CGM ON CGM.ReportingOfferID = EGM.ReportingOfferID
	LEFT JOIN kevinc.StagingOffer O ON O.ReportingOfferID = EGM.ReportingOfferID 
	ORDER BY o.ReportingOfferID
