/******************************************************************************
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of 
		the Warehouse database
Notes:	Amended to include TransactionWeekStartingCampaign in PartnerTrans which is a week starting 
		field based on Thursday being day one.

------------------------------------------------------------------------------
Modification History


******************************************************************************/

CREATE PROCEDURE [WHB].[Transactions_PartnerTrans]
AS
BEGIN

	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);
	
	DECLARE @StoredProcedureName VARCHAR(100) = OBJECT_NAME(@@PROCID)
		,	@msg VARCHAR(200)
		,	@RowsAffected INT
		,	@Query VARCHAR(MAX)

	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Started'

	BEGIN TRY

	/*******************************************************************************************************************************************
			1.	[Inbound].[Transactions]
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#FilesToProcess') IS NOT NULL DROP TABLE #FilesToProcess
		SELECT	[f].[ID] AS FileID
			,	[f].[LoadDate]
			,	[f].[FileName]
		INTO #FilesToProcess
		FROM [WHB].[Inbound_Files] f
		WHERE [f].[TableName] = 'Transactions'
	
		SET DATEFIRST 1; --set the first day of the week to Monday. This influences the return value of DATEPART()
		
		DECLARE @Today DATE = GETDATE()

		IF OBJECT_ID('tempdb..#IronOffer_SpendStretch') IS NOT NULL DROP TABLE #IronOffer_SpendStretch;
		SELECT	iof.IronOfferID
			,	MIN(pcr.MinimumBasketSize) AS MinimumBasketSize
		INTO #IronOffer_SpendStretch
		FROM [Derived].[IronOffer] iof
		INNER JOIN [Derived].[IronOffer_PartnerCommissionRule] pcr
			ON iof.IronOfferID = pcr.IronOfferID
		WHERE pcr.TypeID = 1
		AND pcr.DeletionDate IS NULL
		AND pcr.MinimumBasketSize IS NOT NULL
		GROUP BY iof.IronOfferID

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer_SpendStretch (IronOfferID)

		IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
		SELECT	*
		INTO #Transactions
		FROM [Inbound].[Transactions] tr
		WHERE [tr].[OfferID] IS NOT NULL
		
		CREATE CLUSTERED INDEX CIX_CardID ON #Transactions (CardID)
		CREATE NONCLUSTERED INDEX IX_MerchantID ON #Transactions (MerchantID)

		IF OBJECT_ID('tempdb..#Inbound_Cards') IS NOT NULL DROP TABLE #Inbound_Cards
		SELECT	*
		INTO #Inbound_Cards
		FROM [WHB].[Inbound_Cards] ca
		WHERE EXISTS (	SELECT	1
						FROM #Transactions tr
						WHERE #Transactions.[ca].CardID = tr.CardID)

		CREATE CLUSTERED INDEX CIX_CardID ON #Inbound_Cards (CardID)

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
		SELECT	*
		INTO #RetailOutlet
		FROM OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro
		WHERE EXISTS (	SELECT	1
						FROM #Transactions tr
						WHERE #Transactions.[ro].MerchantID = tr.MerchantID)

		CREATE CLUSTERED INDEX CIX_MerchantID ON #RetailOutlet (MerchantID)

		

		IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
		SELECT	DISTINCT
				ftp.FileID
			,	RowNum = ROW_NUMBER() OVER (PARTITION BY ftp.FileID ORDER BY tr.TransactionDate, tr.TransactionTime, tr.Amount, tr.CardID, tr.OfferID)
			,	FanID = ca.PrimaryCustomerID
			,	PartnerID = iof.PartnerID
			,	OutletID = COALESCE(ro.ID, -1)
			,	IsOnline =	CASE
								WHEN tr.CardholderPresent = '5' THEN 1
								WHEN tr.CardholderPresent = '9' AND ro.Channel = 1 THEN 1
								WHEN iof.PartnerID = 4920 THEN 1
								ELSE 0
							END
			,	CardholderPresentData = tr.CardholderPresent
			,	TransactionAmount = tr.Amount
			,	ExtremeValueFlag = 0
			,	TransactionDate = CONVERT(DATETIME2(0), CONVERT(DATETIME, tr.TransactionDate) + CONVERT(DATETIME, tr.TransactionTime))
			,	TransactionWeekStarting = DATEADD(dd, - 1 * (DATEPART(dw, tr.TransactionDate) - 1) , tr.TransactionDate)
			,	TransactionMonth = MONTH(tr.TransactionDate)
			,	TransactionYear = YEAR(tr.TransactionDate)
			,	TransactionWeekStartingCampaign = CASE
													WHEN DATEADD(dd, 3, DATEADD(dd, - 1 * (DATEPART(dw, tr.TransactionDate) - 1) , tr.TransactionDate)) > tr.TransactionDate THEN DATEADD(dd,-4,DATEADD(dd, - 1 * (DATEPART(dw, tr.TransactionDate) - 1) , tr.TransactionDate))
													ELSE DATEADD(dd, 3, DATEADD(dd, - 1 * (DATEPART(dw, tr.TransactionDate) - 1) , tr.TransactionDate))
											  END
			,	AddedDate = tr.LoadDate			
			,	AddedWeekStarting = DATEADD(dd, - 1 * (DATEPART(dw, tr.LoadDate) - 1) , tr.LoadDate)
			,	AddedMonth = MONTH(tr.LoadDate)
			,	AddedYear = YEAR(tr.LoadDate)
			
			,	AffiliateCommissionAmount = tr.CashbackAmount + (pd.Override * tr.CashbackAmount)
			,	CommissionChargable = tr.CashbackAmount + (pd.Override * tr.CashbackAmount)
			,	CashbackEarned = tr.CashbackAmount
			,	IronOfferID = COALESCE(tr.OfferID, iof.ID)
			,	ActivationDays =	CASE
										WHEN tr.CashbackAmount > 0 THEN 35
										ELSE 0
									END
			,	AboveBase =	CASE
								WHEN ss.MinimumBasketSize IS NULL THEN NULL
								WHEN ss.MinimumBasketSize < tr.Amount THEN 1
								ELSE 0
							END
			,	PaymentMethodID = 1
			,	tr.UniqueTransactionID
		INTO #PartnerTrans
		FROM #Transactions tr
		INNER JOIN #Inbound_Cards ca
			ON tr.CardID = ca.CardID
		LEFT JOIN #FilesToProcess ftp
			ON tr.FileName = ftp.FileName
			AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, ftp.LoadDate)
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[hydra].[OfferConverterAudit] oca
			ON tr.VirginOfferID = oca.HydraOfferID
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
			ON oca.IronOfferID = iof.ID
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON iof.PartnerID = pd.PartnerID
			AND pd.ClubID = 166
			AND tr.TransactionDate BETWEEN pd.StartDate AND COALESCE(pd.EndDate, @Today)
		LEFT JOIN #IronOffer_SpendStretch ss
			ON iof.ID = ss.IronOfferID
		LEFT JOIN #RetailOutlet ro
			ON tr.MerchantID = ro.MerchantID
			AND iof.PartnerID = ro.PartnerID
		WHERE iof.IsSignedOff = 1

		--Flag the extreme values on the transactions
		
		IF OBJECT_ID('tempdb..#ExtremeValues') IS NOT NULL DROP TABLE #ExtremeValues
		SELECT	pt.FileID
			,	pt.RowNum
			,	pt.PartnerID
			,	pt.TransactionAmount
			,	ValuePercentile = NTILE(100) OVER (PARTITION BY [pt].[PartnerID] ORDER BY [pt].[TransactionAmount])
		INTO #ExtremeValues
		FROM #PartnerTrans pt
		ORDER BY [pt].[PartnerID];

		UPDATE pt
		SET pt.ExtremeValueFlag = 1
		FROM #PartnerTrans pt
		INNER JOIN #ExtremeValues ev
			ON pt.FileID = ev.FileID
			AND pt.RowNum = ev.RowNum
		WHERE ev.ValuePercentile NOT BETWEEN 6 AND 95;		--Top and bottom 5% of transactions are flagged as extreme values

		CREATE CLUSTERED INDEX CIX_FileIDRowNum ON #PartnerTrans (FileID, RowNum)
	
		INSERT INTO [Derived].[PartnerTrans]
		SELECT	[pts].[FileID]
			,	[pts].[RowNum]
			,	[pts].[FanID]
			,	[pts].[PartnerID]
			,	[pts].[OutletID]
			,	[pts].[IsOnline]
			,	[pts].[CardholderPresentData]
			,	[pts].[TransactionAmount]
			,	[pts].[ExtremeValueFlag]
			,	[pts].[TransactionDate]
			,	[pts].[TransactionWeekStarting]
			,	[pts].[TransactionMonth]
			,	[pts].[TransactionYear]
			,	[pts].[TransactionWeekStartingCampaign]
			,	[pts].[AddedDate]
			,	[pts].[AddedWeekStarting]
			,	[pts].[AddedMonth]
			,	[pts].[AddedYear]
			,	[pts].[AffiliateCommissionAmount]
			,	[pts].[CommissionChargable]
			,	[pts].[CashbackEarned]
			,	[pts].[IronOfferID]
			,	[pts].[ActivationDays]
			,	[pts].[AboveBase]
			,	[pts].[PaymentMethodID]
			,	[pts].[UniqueTransactionID]
		FROM #PartnerTrans pts
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[PartnerTrans] ptd
							WHERE pts.FileID = ptd.FileID
							AND pts.RowNum = ptd.RowNum)

		-- log it
		SET @RowsAffected = @@ROWCOUNT;SET @msg = 'Loaded rows to [Derived].[PartnerTrans] [' + CAST(@RowsAffected AS VARCHAR(10)) + ']'
		EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, @msg

		EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'

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
			INSERT INTO [Monitor].[ErrorLog] ([Monitor].[ErrorLog].[ErrorDate], [Monitor].[ErrorLog].[ProcedureName], [Monitor].[ErrorLog].[ErrorLine], [Monitor].[ErrorLog].[ErrorMessage], [Monitor].[ErrorLog].[ErrorNumber], [Monitor].[ErrorLog].[ErrorSeverity], [Monitor].[ErrorLog].[ErrorState])
			VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

		-- Regenerate an error to return to caller
			SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
			RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

		-- Return a failure
			RETURN -1;

	END CATCH

	RETURN 0; -- should never run

END