/******************************************************************************
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of the Warehouse database
Notes:	

------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE [WHB].[Transactions_SchemeTrans_FromMatchedTransaction]
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
			1.		[PANless_Transaction]
	*******************************************************************************************************************************************/

		--	Now = GETDATE()
		--	ClubID = 182;
			
		IF OBJECT_ID('tempdb..#MatchedTransactions') IS NOT NULL DROP TABLE #MatchedTransactions;
		SELECT	DISTINCT
				ID = mt.ID
			,	TransactionGUID = mt.TransactionGUID
			,	TransactionExternalId = mt.TransactionExternalId
			,	PartnerID = iof.PartnerID
			,	MerchantID = mt.MerchantID
			,	OIN = mt.OIN
			,	IronOfferID = iof.IronOfferID
			,	CustomerGUID = mt.CustomerGUID
			,	TransactionDate = mt.TransactionDate
			,	Price = mt.Price
			,	CashbackEarned = mt.CashbackEarned
			,	OfferRate = mt.OfferRate
			,	CommissionRate = mt.CommissionRate
			,	NetAmount =	mt.NetAmount
			,	VATAmount =	mt.VATAmount
			,	GrossAmount = mt.GrossAmount
			,	MatchedDate = mt.MatchedDate
			,	FileName = mt.FileName
			,	LoadDate = mt.LoadDate
		INTO #MatchedTransactions
		FROM [Inbound].[MatchedTransactions] mt
		INNER JOIN [Derived].[IronOffer] iof
			ON mt.OfferGUID = iof.HydraOfferID
		WHERE mt.TransactionTypeID IN (1, 7)
			
		IF OBJECT_ID('tempdb..#PANless_Transaction') IS NOT NULL DROP TABLE #PANless_Transaction;
		SELECT	DISTINCT
				ID = mt.ID
			,	TransactionGUID = mt.TransactionGUID
			,	TransactionExternalId = mt.TransactionExternalId
			,	ImportDate = GETDATE()
			,	DetailIdentifier = 'D'
			,	PartnerID = mt.PartnerID
			,	ClubID = 182
			,	CurrencyCode = 'GBR'
			,	MerchantNumber = mt.MerchantID
			,	OIN = mt.OIN
			,	MaskedCardNumber = NULL											--	Update
			,	RewardOfferID = mt.IronOfferID
			,	CustomerID = mt.CustomerGUID
			,	FanID = cu.FanID
			,	TransactionDate = mt.TransactionDate
			,	TransactionAmount = mt.Price
			,	CashbackAmount = mt.CashbackEarned
			,	OfferRate = mt.OfferRate
			,	CommissionRate = mt.CommissionRate
			,	NetAmount =	mt.NetAmount
			,	VATCommission =	mt.VATAmount
			,	GrossCommission = mt.GrossAmount
			,	PublisherID = 182
			,	FileID = ibf.ID
			,	ImportedToPANlessDateTime = mt.MatchedDate
			,	mt.FileName
			,	mt.LoadDate
		INTO #PANless_Transaction
		FROM #MatchedTransactions mt
		INNER JOIN [WHB].[Inbound_Files] ibf
			ON mt.FileName = ibf.FileName
			AND CONVERT(DATE, mt.LoadDate) = ibf.LoadDate
		INNER JOIN [Derived].[Customer] cu
			ON mt.CustomerGUID = cu.CustomerGUID

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
		
		IF OBJECT_ID('tempdb..#RetailOutletHashed') IS NOT NULL DROP TABLE #RetailOutletHashed;
		SELECT	ID = MAX(CONVERT(INT, ro.ID))
			,	MerchantID = REPLACE(ro.MerchantID, '#', '')
			,	PartnerID = ro.PartnerID
			,	Channel = MIN(CONVERT(INT, ro.Channel))
		INTO #RetailOutletHashed
		FROM OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro
		WHERE MerchantID LIKE '%#%'
		GROUP BY	REPLACE(ro.MerchantID, '#', '')
				,	ro.PartnerID
		
		IF OBJECT_ID('tempdb..#RetailOutlet_Temp') IS NOT NULL DROP TABLE #RetailOutlet_Temp;
		SELECT	ID = MAX(CONVERT(INT, ro.ID))
			,	MerchantID = ro.MerchantID
			,	PartnerID = ro.PartnerID
			,	Channel = MIN(CONVERT(INT, ro.Channel))
		INTO #RetailOutlet_Temp
		FROM OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro
		WHERE MerchantID NOT LIKE '%#%'
		GROUP BY	ro.MerchantID
				,	ro.PartnerID

		INSERT INTO #RetailOutlet_Temp
		SELECT	ID = ro.ID
			,	MerchantID = ro.MerchantID
			,	PartnerID = ro.PartnerID
			,	Channel = ro.Channel
		FROM #RetailOutletHashed ro
		WHERE NOT EXISTS (	SELECT 1
							FROM #RetailOutlet_Temp ro2
							WHERE ro.MerchantID = ro2.MerchantID
							AND ro.PartnerID = ro2.PartnerID)

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet;
		SELECT	PartnerID = ro.PartnerID
			,	MerchantID = ro.MerchantID
			,	RetailOutletID = ro.ID
			,	Channel = ro.Channel
			,	IsOnline =	CASE
								WHEN ro.Channel = 1 THEN 1
								ELSE 0
							END
		INTO #RetailOutlet
		FROM #RetailOutlet_Temp ro

		CREATE CLUSTERED INDEX CIX_MerchantID ON #RetailOutlet (PartnerID, MerchantID, RetailOutletID, IsOnline)

		
		IF OBJECT_ID('tempdb..#DirectDebitOriginator') IS NOT NULL DROP TABLE #DirectDebitOriginator
		SELECT	DirectDebitOriginatorID = ddo.ID
			,	OIN = ddo.OIN
		INTO #DirectDebitOriginator
		FROM [SLC_Report].[dbo].[DirectDebitOriginator] ddo
		WHERE EXISTS (	SELECT	1
						FROM #PANless_Transaction pt
						WHERE ddo.OIN = pt.OIN)

		CREATE CLUSTERED INDEX CIX_OIN ON #DirectDebitOriginator (OIN)
								
		IF OBJECT_ID('tempdb..#SchemeTrans_Temp') IS NOT NULL DROP TABLE #SchemeTrans_Temp;
		SELECT	ID = pt.ID
			,	TransactionGUID = pt.TransactionGUID
			,	TransactionExternalId = pt.TransactionExternalId
			,	Spend = pt.TransactionAmount
			,	RetailerCashback = pt.CashbackAmount
			,	TranDate = pt.TransactionDate
			,	AddedDate = pt.ImportDate
			,	pt.FanID
			,	pt.PartnerID
			,	pt.MaskedCardNumber
			,	RetailerID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID)
			,	Investment = pt.NetAmount
			,	pt.MerchantNumber
			,	pt.OIN
			,	OutletID = ro.RetailOutletID
			,	DirectDebitOriginatorID = ddo.DirectDebitOriginatorID
			,	IsOnline =	CASE
								WHEN ro.Channel = 1 THEN 1
								ELSE 0
							END
			,	IronOfferID = pt.RewardOfferID
			,	SpendStretchAmount = NULLIF(ss.MinimumBasketSize, 0)
			,	CatchUpDate = CONVERT(DATE, NULL)
			,	PublisherShare = ISNULL(pd.Publisher, 0)
			,	RewardShare = ISNULL(pd.Reward, 100)
			,	pt.PublisherID
			,	CheckDate = pt2.CheckDate
			,	IsNegative =	CASE
									WHEN pt.TransactionAmount < 0 THEN 1
									ELSE 0
								END
			,	TranFixDate =	CASE
									WHEN pt.ImportDate <= pt2.CheckDate THEN pt.TransactionDate
									ELSE NULL
								END
			,	CommissionRate = pt.CommissionRate
			,	Commission = pt.NetAmount - pt.CashbackAmount
			,	VATCommission = pt.VATCommission
			,	GrossCommission = pt.GrossCommission
			,	IsSpendStretch =	CASE
										WHEN ss.MinimumBasketSize IS NULL THEN NULL
										WHEN ss.MinimumBasketSize <= pt.TransactionAmount THEN 1
										ELSE 0
									END
			,	RewardCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN (pt.NetAmount - pt.CashbackAmount)
										ELSE (pt.NetAmount - pt.CashbackAmount) - (((pt.NetAmount - pt.CashbackAmount) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100)))
									END
			,	PublisherCommission =	CASE
											WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
											ELSE ((pt.NetAmount - pt.CashbackAmount) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100))
										END
										
			,	OfferPercentage =	pt.OfferRate
			,	Override = ISNULL(pd.[Override], 0.35)
			,	pt.FileName
			,	pt.LoadDate
		INTO #SchemeTrans_Temp
		FROM #PANless_Transaction pt
		LEFT JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
			ON pt.PartnerID = pri.PartnerID
		LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
			ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pd.PartnerID
			AND pt.ClubID = pd.ClubID
		LEFT JOIN [Derived].[IronOffer] iof
			ON pt.RewardOfferID = iof.IronOfferID
		LEFT JOIN #IronOffer_SpendStretch ss
			ON pt.RewardOfferID = ss.IronOfferID
		LEFT JOIN #RetailOutlet ro
			ON pt.MerchantNumber = ro.MerchantID
			AND iof.PartnerID = ro.PartnerID
		LEFT JOIN #DirectDebitOriginator ddo
			ON pt.OIN = ddo.OIN
		CROSS APPLY (	SELECT	CheckDate = DATEADD(DAY, 15, EOMONTH(TransactionDate))) pt2
								
		INSERT INTO [Staging].[SchemeTrans]
		SELECT	ID = stt.ID
			,	SchemeTransID = (ROW_NUMBER() OVER (ORDER BY stt.ID) + (SELECT COALESCE(MAX(SchemeTransID), 0) FROM [Staging].[SchemeTrans] WHERE SchemeTransID > 0))
			,	stt.Spend
			,	stt.RetailerCashback
			,	stt.TranDate
			,	stt.AddedDate
			,	stt.FanID
			,	stt.RetailerID
			,	stt.PublisherID
			,	PublisherCommission = CONVERT(DECIMAL(32,2), stt.PublisherCommission)
			,	RewardCommission = CONVERT(DECIMAL(32,2), stt.RewardCommission)
			,	stt.TranFixDate
			,	stt.IsNegative
			,	stt.Investment
			,	stt.IsOnline
			,	CASE
					WHEN stt.TranFixDate IS NULL THEN CONVERT(BIT, 0)
					ELSE CONVERT(BIT, 1) 
				END AS IsRetailMonthly
			,	CONVERT(BIT, 0) AS NotRewardManaged
			,	RewardCommission = CONVERT(DECIMAL(32,2), stt.SpendStretchAmount)
			,	stt.IsSpendStretch
			,	stt.IronOfferID
			,	stt.OutletID
			,	stt.DirectDebitOriginatorID
			,	NULL AS PanID
			,	CONVERT(TINYINT, 0) AS SubPublisherID
			,	CONVERT(BIT, 1) AS IsRetailerReport
			,	stt.OfferPercentage
			,	stt.CommissionRate
			,	stt.VATCommission
			,	stt.GrossCommission
			,	CONVERT(TIME, stt.TranDate) AS TranTime
			,	0 AS Imported
			,	MaskedCardNumber
			,	TransactionGUID
		FROM #SchemeTrans_Temp stt
		WHERE NOT EXISTS (	SELECT 1
							FROM [Staging].[SchemeTrans] st
							WHERE stt.ID = st.ID)


		UPDATE ibf
		SET ibf.FileProcessed = 1
		FROM [WHB].[Inbound_Files] ibf
		WHERE ibf.TableName = 'MatchedTransactions'
		AND EXISTS (SELECT 1
					FROM #SchemeTrans_Temp stt
					WHERE ibf.FileName = stt.FileName
					AND CONVERT(DATE, ibf.LoadDate) = CONVERT(DATE, stt.LoadDate)
					AND EXISTS (	SELECT 1
									FROM [Staging].[SchemeTrans] st
									WHERE stt.TransactionGUID = st.TransactionGUID
									AND st.Imported = 0))
		
		-- log it

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
