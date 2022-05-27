/******************************************************************************
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of the Warehouse database
Notes:	

------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE [WHB].[SchemeTrans_MatchedTransactions_VisaBarclaycard]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	--EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

	/*******************************************************************************************************************************************
			1.		[PANless_Transaction]
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#RetailOutletHashed') IS NOT NULL DROP TABLE #RetailOutletHashed;
		SELECT	CONVERT(INT, ro.ID) AS ID
			,	REPLACE(ro.MerchantID, '#', '') AS MerchantID
			,	ro.PartnerID
			,	ro.Channel
		INTO #RetailOutletHashed
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		WHERE MerchantID LIKE '%#%'
		
		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
		SELECT	CONVERT(INT, ro.ID) AS ID
			,	ro.MerchantID
			,	ro.PartnerID
			,	IsOnline =	CASE
								WHEN ro.Channel = 1 THEN 1
								ELSE 0
							END
		INTO #RetailOutlet
		FROM [SLC_REPL].[dbo].[RetailOutlet] ro
		WHERE MerchantID NOT LIKE '%#%'

		INSERT INTO #RetailOutlet
		SELECT	ro.ID
			,	MerchantID
			,	ro.PartnerID
			,	IsOnline =	CASE
								WHEN ro.Channel = 1 THEN 1
								ELSE 0
							END
		FROM #RetailOutletHashed ro
		WHERE NOT EXISTS (	SELECT 1
							FROM #RetailOutlet ro2
							WHERE ro.MerchantID = ro2.MerchantID)

		CREATE CLUSTERED INDEX CIX_MerchantID ON #RetailOutlet (MerchantID)

		DECLARE	@Now DATETIME = GETDATE()
			,	@ClubID INT = 180;
			
		IF OBJECT_ID('tempdb..#PANless_Transaction') IS NOT NULL DROP TABLE #PANless_Transaction;
		SELECT	SourceID = 3
			,	SourceTableID = mt.ID
			,	PublisherID = @ClubID
			,	SubPublisherID = 0
			,	NotRewardManaged = 0
			,	RetailerID = iof.RetailerID
			,	PartnerID = iof.PartnerID
			,	OfferID = iof.OfferID
			,	IronOfferID = iof.IronOfferID
			,	OfferPercentage = mt.OfferRate
			,	CommissionRate = mt.CommissionRate
			,	OutletID = ro.ID
			,	MerchantNumber = mt.MerchantID
		
		,	FanID = cu.FanID
		,	PanID = NULL
		
		,	Spend = mt.Price
		,	RetailerCashback = mt.CashbackEarned
		,	Investment = mt.NetAmount

		,	PublisherCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
										ELSE (CONVERT(DECIMAL(32,2), ((CONVERT(DECIMAL(32,2), mt.NetAmount - mt.CashbackEarned)) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100))))
									END
		,	RewardCommission =		CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN (CONVERT(DECIMAL(32,2), mt.NetAmount - mt.CashbackEarned))
										ELSE (CONVERT(DECIMAL(32,2), mt.NetAmount - mt.CashbackEarned)) - (CONVERT(DECIMAL(32,2), ((CONVERT(DECIMAL(32,2), mt.NetAmount - mt.CashbackEarned)) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100))))
									END

		,	VATCommission = mt.VATAmount
		,	GrossCommission = mt.GrossAmount
		,	TranDate = mt.TransactionDate

		,	TranFixDate =	CASE
								WHEN mt.MatchedDate <= DATEADD(DAY, 15, EOMONTH(mt.TransactionDate)) THEN mt.TransactionDate
								ELSE NULL
							END

		,	TranTime = CONVERT(TIME, mt.TransactionDate)
		,	IsNegative =	CASE
								WHEN mt.Price < 0 THEN 1
								ELSE 0
							END
		,	IsOnline = COALESCE(ro.IsOnline, 0)
		,	IsSpendStretch =	CASE
									WHEN iof.SpendStretchAmount_1 < mt.Price THEN 1
									WHEN iof.SpendStretchAmount_1 IS NULL THEN NULL
									ELSE 0
								END
		,	SpendStretchAmount = iof.SpendStretchAmount_1

		,	IsRetailMonthly =	CASE
									WHEN mt.MatchedDate <= DATEADD(DAY, 15, EOMONTH(mt.TransactionDate)) THEN CONVERT(BIT, 1)
									ELSE CONVERT(BIT, 0)
								END
		,	IsRetailerReport = CONVERT(BIT, 1)

		,	AddedDate = mt.MatchedDate
		INTO #PANless_Transaction
		FROM [WH_Visa].[Inbound].[MatchedTransactions] mt
		INNER JOIN [WH_Visa].[WHB].[Inbound_Files] ibf
			ON mt.FileName = ibf.FileName
			AND CONVERT(DATE, mt.LoadDate) = ibf.LoadDate
		INNER JOIN [Derived].[Customer] cu
			ON mt.CustomerGUID = cu.CustomerGUID
			AND cu.PublisherID = @ClubID
		INNER JOIN [Derived].[Offer] iof
			ON mt.OfferGUID = iof.OfferGUID
			AND iof.PublisherID = @ClubID
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON iof.RetailerID = pd.PartnerID
			AND @ClubID = pd.ClubID
			AND mt.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
		LEFT JOIN #RetailOutlet ro
			ON mt.MerchantID = ro.MerchantID
			AND iof.PartnerID = ro.PartnerID
		WHERE mt.TransactionTypeID IN (1, 7)
		AND NOT EXISTS (	SELECT 1
							FROM [Derived].[SchemeTrans] st
							WHERE mt.ID = st.SourceTableID
							AND st.SourceID = 3)

	INSERT INTO [Derived].[SchemeTrans]	(	[SourceID]
										,	[SourceTableID]
										,	[PublisherID]
										,	[SubPublisherID]
										,	[NotRewardManaged]
										,	[RetailerID]
										,	[PartnerID]
										,	[OfferID]
										,	[IronOfferID]
										,	[OfferPercentage]
										,	[CommissionRate]
										,	[OutletID]
										,	[FanID]
										,	[PanID]
									--	,	[MaskedCardNumber]
										,	[Spend]
										,	[RetailerCashback]
										,	[Investment]
										,	[PublisherCommission]
										,	[RewardCommission]
										,	[VATCommission]
										,	[GrossCommission]
										,	[TranDate]
										,	[TranFixDate]
										,	[TranTime]
										,	[IsNegative]
										,	[IsOnline]
										,	[IsSpendStretch]
										,	[SpendStretchAmount]
										,	[IsRetailMonthly]
										,	[IsRetailerReport]
										,	[AddedDate])
		SELECT	DISTINCT
				SourceID = pt.SourceID
			,	SourceTableID = pt.SourceTableID
			,	PublisherID = pt.PublisherID
			,	SubPublisherID = pt.SubPublisherID
			,	NotRewardManaged = pt.NotRewardManaged
			,	RetailerID = pt.RetailerID
			,	PartnerID = pt.PartnerID
			,	OfferID = pt.OfferID
			,	IronOfferID = pt.IronOfferID
			,	OfferPercentage = pt.OfferPercentage
			,	CommissionRate = pt.CommissionRate
			,	OutletID = pt.OutletID
		--	,	MerchantNumber = pt.MerchantNumber
		
			,	FanID = pt.FanID
			,	PanID = pt.PanID
		
			,	Spend = pt.Spend
			,	RetailerCashback = pt.RetailerCashback
			,	Investment = pt.Investment
		
			,	PublisherCommission = pt.PublisherCommission
			,	RewardCommission = pt.RewardCommission

			,	VATCommission = pt.VATCommission
			,	GrossCommission = pt.GrossCommission
			,	TranDate = pt.TranDate

			,	TranFixDate = pt.TranFixDate

			,	TranTime = pt.TranTime
			,	IsNegative = pt.IsNegative
			,	IsOnline = pt.IsOnline
			,	IsSpendStretch = pt.IsSpendStretch
			,	SpendStretchAmount = pt.SpendStretchAmount
		
			,	IsRetailMonthly = pt.IsRetailMonthly
			,	IsRetailerReport = pt.IsRetailerReport

			,	AddedDate = pt.AddedDate
		FROM #PANless_Transaction pt
		WHERE pt.FanID IS NOT NULL
		AND pt.OfferID IS NOT NULL
		AND pt.OutletID != -1
		
		-- log it

		--EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

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
			INSERT INTO [Monitor].[ErrorLog] (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END