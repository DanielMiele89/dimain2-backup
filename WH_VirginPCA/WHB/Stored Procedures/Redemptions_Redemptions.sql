
CREATE PROCEDURE [WHB].[Redemptions_Redemptions]
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

	/***********************************************************************************************************************************************
			1.		Insert all new Trade Up Redemptions
	***********************************************************************************************************************************************/

		/*******************************************************************************************************************************************
				1.1.	Fetch all new Trade Up Redemptions
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#TradeUp_Redemptions') IS NOT NULL DROP TABLE #TradeUp_Redemptions
			SELECT	ir.*
			INTO #TradeUp_Redemptions
			FROM [Inbound].[Redemptions] ir
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE ir.[RedemptionTransactionGUID] = r.[TransactionGUID])

			CREATE CLUSTERED INDEX CIX_TranGUID ON #TradeUp_Redemptions (RedemptionTransactionGUID)


		/*******************************************************************************************************************************************
				1.2.	Insert new Trade Up Redemptions to [Derived].[Redemptions]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Redemptions]
			SELECT	DISTINCT
					tur.Currency
				,	RedemptionType = 'Trade Up'
				,	ro.RedemptionPartnerGUID
				,	ri.RedemptionOfferGUID
				,	TransactionGUID = tur.RedemptionTransactionGUID
				,	TradeUp_RedemptionItemID = tur.RedemptionItemID
				,	tur.CustomerGUID
				,	cu.FanID
				,	CashbackUsed = tur.Amount
				,	CashbackEarned = tur.Cashback
				,	tur.RedeemedDate
				,	tur.ConfirmedDate
			FROM #TradeUp_Redemptions tur
			INNER JOIN [Derived].[Customer] cu
				ON tur.CustomerGUID = cu.CustomerGUID
			INNER JOIN [Derived].[RedemptionItems] ri
				ON tur.RedemptionItemID = ri.RedemptionItemID
			INNER JOIN [Derived].[RedemptionOffers] ro
				ON ri.RedemptionOfferGUID = ro.RedemptionOfferGUID
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE tur.[RedemptionTransactionGUID] = r.[TransactionGUID])

		/***********************************************************************************************************************************************
				1.3.	Update [WHB].[Inbound_Files] to show file has been processed
		***********************************************************************************************************************************************/

			;WITH
			InsertedRedemptions AS (SELECT	DISTINCT
											FileName
										,	LoadDate
									FROM #TradeUp_Redemptions tur
									WHERE EXISTS (	SELECT 1
													FROM [Derived].[Redemptions] r
													WHERE tur.[RedemptionTransactionGUID] = r.[TransactionGUID]))
			UPDATE ibf
			SET ibf.FileProcessed = 1
			FROM [WHB].[Inbound_Files] ibf
			WHERE EXISTS (	SELECT 1
							FROM InsertedRedemptions ir
							WHERE ibf.FileName = ir.FileName
							AND ibf.LoadDate = ir.LoadDate)

	/***********************************************************************************************************************************************
			2.		Insert all new Charity Redemptions
	***********************************************************************************************************************************************/
		
		/*******************************************************************************************************************************************
				2.1.		Fetch all new Charity Redemptions
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#Charity_Redemptions') IS NOT NULL DROP TABLE #Charity_Redemptions
			SELECT	cr.*
			INTO #Charity_Redemptions
			FROM [Inbound].[CharityRedemptions] cr
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE cr.[DonationTransactionGUID] = r.[TransactionGUID])

			CREATE CLUSTERED INDEX CIX_TranGUID ON #Charity_Redemptions ([DonationTransactionGUID])


		/*******************************************************************************************************************************************
				2.2.		Insert new Charity Redemptions to [Derived].[Redemptions]
		*******************************************************************************************************************************************/

			INSERT INTO [Derived].[Redemptions]
			SELECT	DISTINCT
					cr.Currency
				,	RedemptionType = 'Charity'
				,	ro.RedemptionPartnerGUID
				,	ro.RedemptionOfferGUID
				,	TransactionGUID = cr.DonationTransactionGUID
				,	TradeUp_RedemptionItemID = NULL
				,	cr.CustomerGUID
				,	cu.FanID
				,	CashbackUsed = cr.Amount
				,	CashbackEarned = 0
				,	cr.RedeemedDate
				,	cr.ConfirmedDate
			FROM #Charity_Redemptions cr
			INNER JOIN [Derived].[Customer] cu
				ON cr.CustomerGUID = cu.CustomerGUID
			INNER JOIN [Derived].[RedemptionOffers] ro
				ON cr.CharityOfferID = ro.RedemptionOfferID
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE cr.[DonationTransactionGUID] = r.[TransactionGUID])

		/***********************************************************************************************************************************************
				2.3.	Update [WHB].[Inbound_Files] to show file has been processed
		***********************************************************************************************************************************************/

			;WITH
			InsertedRedemptions AS (SELECT	DISTINCT
											FileName
										,	LoadDate
									FROM #Charity_Redemptions cr
									WHERE EXISTS (	SELECT 1
													FROM [Derived].[Redemptions] r
													WHERE cr.[DonationTransactionGUID] = r.[TransactionGUID]))
			UPDATE ibf
			SET ibf.FileProcessed = 1
			FROM [WHB].[Inbound_Files] ibf
			WHERE EXISTS (	SELECT 1
							FROM InsertedRedemptions ir
							WHERE ibf.FileName = ir.FileName)

	/***********************************************************************************************************************************************
			3.		Insert all new Charity Redemptions
	***********************************************************************************************************************************************/
		
		/*******************************************************************************************************************************************
				3.1.		Fetch all new Charity Redemptions
		*******************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#Paycard_Redemptions') IS NOT NULL DROP TABLE #Paycard_Redemptions
			SELECT	mt.*
			INTO #Paycard_Redemptions
			FROM [Inbound].[MatchedTransactions] mt
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE mt.[TransactionGUID] = r.[TransactionGUID])
			AND TransactionTypeID IN (2)

			CREATE CLUSTERED INDEX CIX_TranGUID ON #Paycard_Redemptions ([TransactionGUID])

		/*******************************************************************************************************************************************
				3.2.		Insert new Charity Redemptions to [Derived].[Redemptions]
		*******************************************************************************************************************************************/
		
			INSERT INTO [Derived].[Redemptions]
			SELECT	DISTINCT
					Currency = 'GBP'
				,	RedemptionType = 'Pay Card'
				,	pr.RetailerGUID
				,	pr.OfferGUID
				,	TransactionGUID = pr.TransactionGUID
				,	TradeUp_RedemptionItemID = NULL
				,	pr.CustomerGUID
				,	cu.FanID
				,	CashbackUsed = pr.CashbackEarned * -1
				,	CashbackEarned = 0
				,	pr.TransactionDate
				,	pr.MatchedDate
			FROM #Paycard_Redemptions pr
			INNER JOIN [WHB].[Inbound_Cards] ic
				ON pr.CardGUID = ic.CardGUID
			INNER JOIN [Derived].[Customer] cu
				ON pr.CustomerGUID = cu.CustomerGUID
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Redemptions] r
								WHERE pr.[TransactionGUID] = r.[TransactionGUID])

		/***********************************************************************************************************************************************
				3.3.	Update [WHB].[Inbound_Files] to show file has been processed
		***********************************************************************************************************************************************/

			--;WITH
			--InsertedRedemptions AS (SELECT	DISTINCT
			--								FileName
			--							,	LoadDate
			--						FROM #Paycard_Redemptions cr
			--						WHERE EXISTS (	SELECT 1
			--										FROM [Derived].[Redemptions] r
			--										WHERE cr.[TransactionGUID] = r.[TransactionGUID]))
			--UPDATE ibf
			--SET ibf.FileProcessed = 1
			--FROM [WHB].[Inbound_Files] ibf
			--WHERE EXISTS (	SELECT 1
			--				FROM InsertedRedemptions ir
			--				WHERE ibf.FileName = ir.FileName)
							

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