﻿/******************************************************************************
Author:		Suraj Chahal
Date:		21st Aug 2014
Purpose:	To Build the PartnerTrans first in the Staging and then Relational schema of the Warehouse database
Notes:	

------------------------------------------------------------------------------
Modification History
17/09/2021 CJM migration changes: dedupe at marked query
LEFT JOINs changed to INNER JOINs
******************************************************************************/

CREATE PROCEDURE [WHB].[Transactions_SchemeTrans_DIMAIN2]
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

		DECLARE	@Now DATETIME = GETDATE()
			,	@ClubID INT = 166;

		IF OBJECT_ID('tempdb..#PANless_Transaction') IS NOT NULL DROP TABLE #PANless_Transaction;
		SELECT	ID = ROW_NUMBER() OVER (ORDER BY pt.FileID, pt.TransactionDate, pt.CustomerID, pt.Price, pt.AddedDate)
			,	ImportDate = @Now
			,	DetailIdentifier = 'D'
			,	PartnerID = pt.PartnerID
			,	ClubID = fa.ClubID
			,	CurrencyCode = 'GBR'
			,	MerchantNumber = pt.MerchantNumber
			,	MaskedCardNumber = pt.MaskedCardNumber
			,	RewardOfferID = iof.ID
			,	CustomerID = pt.CustomerID
			,	FanID = fa.ID
			,	TransactionDateSTR = CONVERT(DATE, pt.TransactionDate) -- Legacy
			,	TransactionAmountSTR = pt.Price -- Legacy
			,	CashbackAmountSTR = pt.CashbackEarned -- Legacy
			,	TransactionDate = pt.TransactionDate
			,	TransactionAmount = pt.Price
			,	CashbackAmount = pt.CashbackEarned
			,	CommissionRate = pt.CommissionRate
			,	NetAmount = pt.NetAmount
			,	VATCommission = pt.VATAmount
			,	GrossCommission = pt.GrossAmount
			,	PublisherID = ioc.ClubID
			,	FileID = pt.FileID
			,	ImportedToPANlessDateTime = pt.AddedDate
		INTO #PANless_Transaction
		FROM [DIMAIN_TR].[SLC_REPL].[RAS].[PANless_Transaction] pt
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[Fan] fa
			ON pt.CustomerID = fa.SourceUID
			AND fa.ClubID = @ClubID
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[IronOffer] iof
			ON pt.OfferCode = CONVERT(VARCHAR(100), iof.ID)
		INNER JOIN [DIMAIN_TR].[SLC_REPL].[dbo].[IronOfferClub] ioc
			ON iof.ID = ioc.IronOfferID
		WHERE EXISTS (	SELECT 1
						FROM [DIMAIN_TR].[SLC_REPL].[dbo].[CRT_File] crt
						WHERE crt.VectorID = 51
						AND crt.ID = pt.FileID)
		ORDER BY pt.TransactionDate DESC
		-- (52980 rows affected) / 00:00:00

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
		-- (147 rows affected) / 00:00:00

		CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer_SpendStretch (IronOfferID)
						
		IF OBJECT_ID('tempdb..#SchemeTrans_Temp') IS NOT NULL DROP TABLE #SchemeTrans_Temp;
		SELECT	pt.ID
			,	Spend = pt.TransactionAmount
			,	RetailerCashback = pt.CashbackAmount
			,	TranDate = pt.TransactionDate
			,	AddedDate = pt.ImportDate
			,	pt.FanID
			,	pt.PartnerID
			,	pt.MaskedCardNumber
			,	RetailerID = COALESCE(pri.PrimaryPartnerID, pri.PartnerID) -- 
			,	Investment = pt2.Investment
			,	pt.MerchantNumber
			,	ro.ID AS OutletID -- NOT NULL
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
			,	Commission = pt2.Investment - pt.CashbackAmount
			,	VATCommission = pt.VATCommission
			,	GrossCommission = pt.GrossCommission
			,	IsSpendStretch =	CASE
										WHEN ss.MinimumBasketSize IS NULL THEN NULL
										WHEN ss.MinimumBasketSize <= pt.TransactionAmount THEN 1
										ELSE 0
									END
			,	RewardCommission =	CASE
										WHEN ISNULL(pd.Publisher, 0) <= 0 THEN pt2.Commission
										ELSE pt2.Commission - pt2.PublisherCommission
									END
			,	PublisherCommission =	CASE
											WHEN ISNULL(pd.Publisher, 0) <= 0 THEN 0
											ELSE pt2.PublisherCommission
										END
										
			,	OfferPercentage =	CASE
										WHEN CashbackAmount < 0 THEN 0
										ELSE ROUND((pt.CashbackAmount / pt.TransactionAmount) * (100), 1)
									END
			,	Override = ISNULL(pd.[Override], 0.35)
		INTO #SchemeTrans_Temp
		FROM #PANless_Transaction pt
		INNER JOIN OPENQUERY([DIMAIN_TR],'SELECT * FROM [SLC_REPL].[dbo].[RetailOutlet]') ro -- OutletID in [Staging].[SchemeTrans] does not accept NULLs
			ON pt.MerchantNumber = #PANless_Transaction.[ro].MerchantID	
		--LEFT JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
		INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri -- RetailerID in [Staging].[SchemeTrans] does not accept NULLs
			ON pt.PartnerID = #PANless_Transaction.[pri].PartnerID
		--LEFT JOIN [Warehouse].[Relational].[nFI_Partner_Deals] pd
		--	ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pd.PartnerID
		--	AND pt.ClubID = pd.ClubID		
		OUTER APPLY ( -- CJM 17/09/2021 dupes in here
			SELECT TOP(1) #PANless_Transaction.[pd].Publisher, #PANless_Transaction.[pd].Reward, #PANless_Transaction.[pd].[Override]
			FROM [Warehouse].[Relational].[nFI_Partner_Deals] pd
			WHERE COALESCE(#PANless_Transaction.[pri].PrimaryPartnerID, #PANless_Transaction.[pri].PartnerID) = #PANless_Transaction.[pd].PartnerID
				AND pt.ClubID = #PANless_Transaction.[pd].ClubID
			ORDER BY #PANless_Transaction.[EndDate]
		) pd
		LEFT JOIN [Derived].[IronOffer] iof
			ON pt.RewardOfferID = iof.IronOfferID
		LEFT JOIN #IronOffer_SpendStretch ss
			ON pt.RewardOfferID = ss.IronOfferID
		CROSS APPLY (	
			SELECT	CheckDate = DATEADD(DAY, 15, EOMONTH(pt.TransactionDate))
				,	Investment = COALESCE(pt.NetAmount, ROUND(pt.CashbackAmount * (1 + ISNULL(pd.[Override], 0.35)), 2))
				,	Commission = COALESCE(pt.NetAmount, ROUND(pt.CashbackAmount * (1 + ISNULL(pd.[Override], 0.35)), 2)) - pt.CashbackAmount
				,	PublisherCommission = ((COALESCE(pt.NetAmount, ROUND(pt.CashbackAmount * (1 + ISNULL(pd.[Override], 0.35)), 2)) - pt.CashbackAmount) * pd.Publisher / 100) / ((pd.Publisher / 100) + (pd.Reward / 100))
						--FROM #PANless_Transaction pt2
						--WHERE pt.ID = pt2.ID
		) pt2
		-- (53,451 rows affected) / 00:00:01


		INSERT INTO [Staging].[SchemeTrans]
		SELECT	ID = stt.ID
			,	SchemeTransID = (ROW_NUMBER() OVER (ORDER BY stt.ID) + (SELECT COALESCE(MAX([Staging].[SchemeTrans].[SchemeTransID]), 0) FROM [Staging].[SchemeTrans] WHERE [Staging].[SchemeTrans].[SchemeTransID] > 0))
			,	stt.Spend
			,	stt.RetailerCashback
			,	stt.TranDate
			,	stt.AddedDate
			,	stt.FanID
			,	stt.RetailerID
			,	stt.PublisherID
			,	stt.PublisherCommission
			,	stt.RewardCommission
			,	stt.TranFixDate
			,	stt.IsNegative
			,	stt.Investment
			,	stt.IsOnline
			,	CASE
					WHEN stt.TranFixDate IS NULL THEN CONVERT(BIT, 0)
					ELSE CONVERT(BIT, 1) 
				END AS IsRetailMonthly
			,	CONVERT(BIT, 0) AS NotRewardManaged
			,	stt.SpendStretchAmount
			,	stt.IsSpendStretch
			,	stt.IronOfferID
			,	stt.OutletID
			,	NULL AS PanID
			,	CONVERT(TINYINT, 0) AS SubPublisherID
			,	CONVERT(BIT, 1) AS IsRetailerReport
			,	stt.OfferPercentage
			,	stt.CommissionRate
			,	stt.VATCommission
			,	stt.GrossCommission
			,	CONVERT(TIME, stt.TranDate) AS TranTime
			,	0 AS Imported
			,	[stt].[MaskedCardNumber]
		FROM #SchemeTrans_Temp stt
		WHERE NOT EXISTS (	SELECT 1
							FROM [Staging].[SchemeTrans] st
							WHERE stt.ID = st.ID)


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