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
		SELECT	ID AS FileID
			,	LoadDate
			,	FileName
		INTO #FilesToProcess
		FROM [WHB].[Inbound_Files] f
		WHERE TableName = 'MatchedTransactions'
	
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
		SELECT	tr.*
			,	FileID = ftp.FileID
		INTO #Transactions
		FROM [Inbound].[MatchedTransactions] tr
		INNER JOIN #FilesToProcess ftp
			ON tr.FileName = ftp.FileName
			AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, ftp.LoadDate)
		WHERE EXISTS (	SELECT 1
						FROM [Derived].[IronOffer] iof
						WHERE tr.OfferGUID = iof.HydraOfferID)
		AND tr.TransactionTypeID IN (1, 7)

		CREATE CLUSTERED INDEX CIX_CustomerGUID ON #Transactions (CustomerGUID)
		CREATE NONCLUSTERED INDEX IX_MerchantID ON #Transactions (MerchantID)
		CREATE NONCLUSTERED INDEX IX_ ON #Transactions ([FileName],[LoadDate]) INCLUDE ([TransactionGUID],[CustomerGUID],[MerchantID],[Price],[TransactionDate],[OfferGUID],[CashbackEarned],[CommissionRate],[MatchedDate])


		IF OBJECT_ID('tempdb..#RetailOutletHashed') IS NOT NULL DROP TABLE #RetailOutletHashed;
		SELECT	RetailOutletID = MAX(CONVERT(INT, ro.ID))
			,	PartnerID = ro.PartnerID
			,	MerchantID = REPLACE(ro.MerchantID, '#', '')
			,	Channel = MAX(CONVERT(INT, ro.Channel))
		INTO #RetailOutletHashed
		FROM [SLC_Report].[dbo].[RetailOutlet] ro
		WHERE MerchantID LIKE '%#%'
		GROUP BY	REPLACE(ro.MerchantID, '#', '')
				,	ro.PartnerID
		
		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
		SELECT	RetailOutletID = CONVERT(INT, ro.ID)
			,	PartnerID = ro.PartnerID
			,	MerchantID = ro.MerchantID
			,	Channel = CONVERT(INT, ro.Channel)
		INTO #RetailOutlet
		FROM [SLC_Report].[dbo].[RetailOutlet] ro
		WHERE EXISTS (	SELECT	1
						FROM #Transactions tr
						WHERE ro.MerchantID = tr.MerchantID)

		INSERT INTO #RetailOutlet
		SELECT	RetailOutletID = ro.RetailOutletID
			,	PartnerID = ro.PartnerID
			,	MerchantID = ro.MerchantID
			,	Channel = ro.Channel
		FROM #RetailOutletHashed ro
		WHERE EXISTS (		SELECT	1
							FROM #Transactions tr
							WHERE ro.MerchantID = tr.MerchantID)
		AND NOT EXISTS (	SELECT 1
							FROM #RetailOutlet ro2
							WHERE ro.MerchantID = ro2.MerchantID)

		CREATE CLUSTERED INDEX CIX_MerchantID ON #RetailOutlet (MerchantID)
		
		IF OBJECT_ID('tempdb..#DirectDebitOriginator') IS NOT NULL DROP TABLE #DirectDebitOriginator
		SELECT	DirectDebitOriginatorID = ddo.ID
			,	OIN = ddo.OIN
		INTO #DirectDebitOriginator
		FROM [SLC_Report].[dbo].[DirectDebitOriginator] ddo
		WHERE EXISTS (	SELECT	1
						FROM #Transactions tr
						WHERE ddo.OIN = tr.OIN)

		CREATE CLUSTERED INDEX CIX_OIN ON #DirectDebitOriginator (OIN)

		IF OBJECT_ID('tempdb..#PartnerTrans') IS NOT NULL DROP TABLE #PartnerTrans
		SELECT	DISTINCT
				FileID = tr.FileID
			,	TransactionGUID = tr.TransactionGUID
			,	ExternalTransactionID = tr.TransactionExternalId
			,	FanID = cu.FanID
			,	PartnerID = iof.PartnerID
			,	OutletID = CONVERT(INT, ro.RetailOutletID)
			,	DirectDebitOriginatorID = NULL
			,	IsOnline =	CASE
								WHEN ro.Channel = 1 THEN 1
								--WHEN tr.CardholderPresent = '5' THEN 1
								--WHEN tr.CardholderPresent = '9' AND ro.Channel = 1 THEN 1
								ELSE 0
							END
			,	CardholderPresentData = NULL
			,	TransactionAmount = tr.Price
			,	ExtremeValueFlag = 0
			,	TransactionDate = CONVERT(DATETIME2(0),tr.TransactionDate)
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
			
			,	AffiliateCommissionAmount = tr.NetAmount
			,	CommissionChargable = tr.NetAmount
			,	CashbackEarned = tr.CashbackEarned
			,	IronOfferID = iof.IronOfferID
			,	ActivationDays =	CASE
										WHEN tr.CashbackEarned > 0 THEN 35
										ELSE 0
									END
			,	AboveBase =	CASE
								WHEN ss.MinimumBasketSize IS NULL THEN NULL
								WHEN ss.MinimumBasketSize < tr.Price THEN 1
								ELSE 0
							END
			,	PaymentMethodID = 2
		INTO #PartnerTrans
		FROM #Transactions tr
		INNER JOIN [WHB].[Customer] cu
			ON tr.CustomerGUID = cu.CustomerGUID
		INNER JOIN [Derived].[IronOffer] iof
			ON tr.OfferGUID = iof.HydraOfferID
		INNER JOIN #RetailOutlet ro
			ON tr.MerchantID = ro.MerchantID
			AND iof.PartnerID = ro.PartnerID
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON iof.PartnerID = pd.PartnerID
			AND pd.ClubID = 182
			AND tr.TransactionDate BETWEEN pd.StartDate AND COALESCE(pd.EndDate, @Today)
		LEFT JOIN #IronOffer_SpendStretch ss
			ON iof.IronOfferID = ss.IronOfferID
			
		INSERT INTO #PartnerTrans
		SELECT	DISTINCT
				FileID = tr.FileID
			,	TransactionGUID = tr.TransactionGUID
			,	ExternalTransactionID = tr.TransactionExternalId
			,	FanID = cu.FanID
			,	PartnerID = iof.PartnerID
			,	OutletID = NULL
			,	DirectDebitOriginatorID = ddo.DirectDebitOriginatorID
			,	IsOnline = 0
			,	CardholderPresentData = NULL
			,	TransactionAmount = tr.Price
			,	ExtremeValueFlag = 0
			,	TransactionDate = CONVERT(DATETIME2(0),tr.TransactionDate)
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
			
			,	AffiliateCommissionAmount = tr.NetAmount
			,	CommissionChargable = tr.NetAmount
			,	CashbackEarned = tr.CashbackEarned
			,	IronOfferID = iof.IronOfferID
			,	ActivationDays =	CASE
										WHEN tr.CashbackEarned > 0 THEN 35
										ELSE 0
									END
			,	AboveBase =	CASE
								WHEN ss.MinimumBasketSize IS NULL THEN NULL
								WHEN ss.MinimumBasketSize < tr.Price THEN 1
								ELSE 0
							END
			,	PaymentMethodID = 3
		FROM #Transactions tr
		INNER JOIN [WHB].[Customer] cu
			ON tr.CustomerGUID = cu.CustomerGUID
		INNER JOIN [Derived].[IronOffer] iof
			ON tr.OfferGUID = iof.HydraOfferID
		INNER JOIN #DirectDebitOriginator ddo
			ON tr.OIN = ddo.OIN
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON iof.PartnerID = pd.PartnerID
			AND pd.ClubID = 182
			AND tr.TransactionDate BETWEEN pd.StartDate AND COALESCE(pd.EndDate, @Today)
		LEFT JOIN #IronOffer_SpendStretch ss
			ON iof.IronOfferID = ss.IronOfferID

		CREATE CLUSTERED INDEX CIX_FileIDRowNum ON #PartnerTrans (FileID, TransactionGUID, ExternalTransactionID)

		--Flag the extreme values on the transactions
		
		IF OBJECT_ID('tempdb..#ExtremeValues') IS NOT NULL DROP TABLE #ExtremeValues
		SELECT	pt.FileID
			,	pt.TransactionGUID
			,	pt.ExternalTransactionID
			,	pt.PartnerID
			,	pt.TransactionAmount
			,	ValuePercentile = NTILE(100) OVER (PARTITION BY PartnerID ORDER BY TransactionAmount)
		INTO #ExtremeValues
		FROM #PartnerTrans pt
		ORDER BY PartnerID;

		CREATE CLUSTERED INDEX CIX_FileIDRowNum ON #ExtremeValues (FileID, TransactionGUID, ExternalTransactionID)

		CREATE NONCLUSTERED INDEX IX_Value_IncFileRow ON #ExtremeValues ([ValuePercentile]) INCLUDE ([FileID],TransactionGUID, ExternalTransactionID)
		
		UPDATE pt
		SET pt.ExtremeValueFlag = 1
		FROM #PartnerTrans pt
		INNER JOIN #ExtremeValues ev
			ON pt.FileID = ev.FileID
			AND pt.TransactionGUID = ev.TransactionGUID
			AND pt.ExternalTransactionID = ev.ExternalTransactionID
		WHERE ev.ValuePercentile NOT BETWEEN 6 AND 95;		--Top and bottom 5% of transactions are flagged as extreme values
		
		
		IF OBJECT_ID('tempdb..#PartnerTransDupes') IS NOT NULL DROP TABLE #PartnerTransDupes
		SELECT	ExternalTransactionID
			,	TransactionGUID
			,	FirstAddedDate = MIN(AddedDate)
		INTO #PartnerTransDupes
		FROM #PartnerTrans pt
		GROUP BY	ExternalTransactionID
				,	TransactionGUID
		HAVING COUNT(*) > 1

		DELETE pt
		FROM #PartnerTrans pt
		WHERE EXISTS (	SELECT 1
						FROM #PartnerTransDupes ptd
						WHERE pt.TransactionGUID = ptd.TransactionGUID
						AND pt.ExternalTransactionID = ptd.ExternalTransactionID
						AND pt.AddedDate != ptd.FirstAddedDate)

		INSERT INTO [Derived].[PartnerTrans]
		SELECT	FileID
			,	RowNum = ROW_NUMBER() OVER (PARTITION BY FileID ORDER BY TransactionGUID, ExternalTransactionID)
			,	FanID
			,	PartnerID
			,	OutletID
			,	DirectDebitOriginatorID
			,	IsOnline
			,	CardholderPresentData
			,	TransactionAmount
			,	ExtremeValueFlag
			,	TransactionDate
			,	TransactionWeekStarting
			,	TransactionMonth
			,	TransactionYear
			,	TransactionWeekStartingCampaign
			,	AddedDate
			,	AddedWeekStarting
			,	AddedMonth
			,	AddedYear
			,	AffiliateCommissionAmount
			,	CommissionChargable
			,	CashbackEarned
			,	IronOfferID
			,	ActivationDays
			,	AboveBase
			,	PaymentMethodID
			,	TransactionGUID
			,	ExternalTransactionID
		FROM #PartnerTrans pts
		WHERE NOT EXISTS (	SELECT 1
							FROM [Derived].[PartnerTrans] ptd
							WHERE pts.TransactionGUID = ptd.TransactionGUID
							AND pts.ExternalTransactionID = ptd.ExternalTransactionID)
		ORDER BY TransactionDate

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
