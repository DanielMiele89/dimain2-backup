

CREATE PROCEDURE [WHB].[__Actito_DailyCalculation_Manual_Archived]
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
		1.	Fetch all active customers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#Customer') IS NOT NULL DROP TABLE #Customer
		SELECT	cu.FanID
			,	cu.SourceUID
			,	cu.ClubID
			,	cu.Title
			,	cup.FirstName
			,	cup.LastName
			,	cup.Email
			,	cup.DOB
			,	cu.MarketableByEmail
			,	cu.PostCodeDistrict
			,	cu.CashbackAvailable
			,	cu.CashbackPending
			,	cu.CashbackLTV
			,	cu.CurrentlyActive
		INTO #Customer
		FROM [Derived].[Customer] cu
		INNER JOIN [Derived].[Customer_PII] cup
			ON cu.FanID = cup.FanID


		CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)
		

	/*******************************************************************************************************************************************
		2.	Fetch customer segments
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#CustomerSegment') IS NOT NULL DROP TABLE #CustomerSegment
		SELECT	ls.FanID
			,	ls.CustomerSegment
		INTO #CustomerSegment
		FROM [Derived].[Customer_LoyaltySegment] ls
		WHERE ls.EndDate IS NULL
		AND EXISTS (SELECT 1
					FROM #Customer cu
					WHERE ls.FanID = cu.FanID)

		CREATE CLUSTERED INDEX CIX_FanID ON #CustomerSegment (FanID)
		

	/*******************************************************************************************************************************************
		3.	Fetch Birthday email customers
	*******************************************************************************************************************************************/
	
		DECLARE @Today_Birthday DATE = GETDATE()

		IF OBJECT_ID('tempdb..#BirthdayEmailCustomers') IS NOT NULL DROP TABLE #BirthdayEmailCustomers
		SELECT	cu.FanID
			,	1 AS Birthday_Flag
			,	CONVERT(NVARCHAR(255), NULL) AS Birthday_Code
			,	CONVERT(DATE, NULL) AS Birthday_CodeExpiryDate
		INTO #BirthdayEmailCustomers
		FROM #Customer cu
		WHERE DATEPART(MONTH, @Today_Birthday) = DATEPART(MONTH, cu.DOB)
		AND DATEPART(DAY, @Today_Birthday) = DATEPART(DAY, cu.DOB)
		AND cu.CurrentlyActive = 1

		CREATE CLUSTERED INDEX CIX_FanID ON #BirthdayEmailCustomers (FanID)

		/*

		Update for Birthday Code details

		*/
		

	/*******************************************************************************************************************************************
		3.	Fetch Earn Confirmation email customers	-	Now done by API, no longer required
	*******************************************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#EarnConfirmationEmailCustomers') IS NOT NULL DROP TABLE #EarnConfirmationEmailCustomers
		SELECT	DISTINCT
				cu.FanID
			,	DATEADD(DAY, -1, GETDATE()) AS EarnConfirmation_Date
		INTO #EarnConfirmationEmailCustomers
		FROM [Inbound].[Transactions] tr
		INNER JOIN [WHB].[Inbound_Cards] ca
			ON tr.CardID = ca.CardID
		INNER JOIN #Customer cu
			ON cu.FanID = ca.PrimaryCustomerID
		WHERE 0 < tr.CashbackAmount
		AND CONVERT(DATE, tr.LoadDate) = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
		AND 1 = 2

		CREATE CLUSTERED INDEX CIX_FanID ON #EarnConfirmationEmailCustomers (FanID)
		

	/*******************************************************************************************************************************************
		4.	Fetch First Earn (POS) email customers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			4.1.	Fetch subset of trans covering all transactions that have been procssed the previous day
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FirstEarnTransTemp') IS NOT NULL DROP TABLE #FirstEarnTransTemp
			SELECT TOP 10000000 *
			INTO #FirstEarnTransTemp
			FROM [Inbound].[Transactions] tr
			WHERE 0 < tr.CashbackAmount
			ORDER BY LoadDate DESC

			CREATE CLUSTERED INDEX CIX_CardID ON #FirstEarnTransTemp (CardID)
	
			DECLARE @Today_FirstEarn DATE = GETDATE()

			IF OBJECT_ID('tempdb..#FirstEarnTrans') IS NOT NULL DROP TABLE #FirstEarnTrans;
			WITH
			FirstEarnTrans AS (	SELECT	tr.FileName
									,	tr.LoadDate
									,	cu.FanID
									,	tr.CardID
									,	tr.VirginOfferID
									,	tr.OfferID
									,	PartnerID = pa.ID
									,	PartnerName = pa.Name
									,	tr.CashbackAmount
									,	TranDate = CONVERT(DATETIME, tr.TransactionDate) + CONVERT(DATETIME, tr.TransactionTime)
									,	TransactionNumber = ROW_NUMBER() OVER (PARTITION BY cu.FanID ORDER BY CONVERT(DATETIME, tr.TransactionDate) + CONVERT(DATETIME, tr.TransactionTime), tr.LoadDate, tr.CardID, tr.CashbackAmount)
								FROM #FirstEarnTransTemp tr
								INNER JOIN [WHB].[Inbound_Cards] ca
									ON tr.CardID = ca.CardID
								INNER JOIN #Customer cu
									ON cu.FanID = ca.PrimaryCustomerID
								INNER JOIN [SLC_REPL].[hydra].[OfferConverterAudit] oca
									ON tr.VirginOfferID = oca.HydraOfferID
								INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
									ON oca.IronOfferID = iof.ID
								INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
									ON iof.PartnerID = pri.PartnerID
								INNER JOIN [SLC_REPL].[dbo].[Partner] pa
									ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID)
								

			SELECT	fet.FileName
				,	fet.LoadDate
				,	fet.FanID
				,	fet.CardID
				,	fet.VirginOfferID
				,	fet.OfferID
				,	fet.PartnerID
				,	fet.PartnerName
				,	fet.CashbackAmount
				,	fet.TranDate
				,	fet.TransactionNumber
			INTO #FirstEarnTrans
			FROM FirstEarnTrans fet
			WHERE TransactionNumber = 1
			--AND CONVERT(DATE, fet.LoadDate) = @Today_FirstEarn


		/***************************************************************************************************************************************
			4.2.	Load new First Earn customers to permanent table
		***************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_FirstEarnDate] (FanID
														,	CardID
														,	TranDate
														,	LoadDate
														,	PartnerID
														,	PartnerName
														,	CashbackAmount)
			SELECT	FanID = fet.FanID
				,	CardID = fet.CardID
				,	TranDate = fet.TranDate
				,	LoadDate = fet.LoadDate
				,	PartnerID = fet.PartnerID
				,	PartnerName = fet.PartnerName
				,	CashbackAmount = fet.CashbackAmount
			FROM #FirstEarnTrans fet
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_FirstEarnDate] fed
								WHERE fet.FanID = fed.FanID)
			ORDER BY fet.LoadDate

		/***************************************************************************************************************************************
			4.3.	Fetch First Earn customers from permanent table
					Taken from permament table rather than temp table to avoid missing customers if process is ran multiple times in one day
		***************************************************************************************************************************************/
				
			DECLARE @Yesterday DATE = DATEADD(DAY, -1, GETDATE())

			IF OBJECT_ID('tempdb..#FirstEarnPOSEmailCustomers') IS NOT NULL DROP TABLE #FirstEarnPOSEmailCustomers
			SELECT	fed.FanID
				,	fed.PartnerName
				,	@Yesterday AS TranDate	--	fed.TranDate
				,	fed.CashbackAmount
				,	'POS' AS FirstEarn_Type
			INTO #FirstEarnPOSEmailCustomers
			FROM [Derived].[Customer_FirstEarnDate] fed
			WHERE CONVERT(DATE, fed.LoadDate) > '2021-02-06'
			--WHERE CONVERT(DATE, fed.LoadDate) = @Today_FirstEarn
		

	/*******************************************************************************************************************************************
		5.	Fetch Reached £5 Balance email customers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			5.1.	Fetch customers who currently have £5 Cashback Available, but didn't in their most recent [Customer_CashbackBalances]
		***************************************************************************************************************************************/

			DECLARE @Today_FivePoundBalance DATE = GETDATE()

			IF OBJECT_ID('tempdb..#Customer_CashbackBalances_R5') IS NOT NULL DROP TABLE #Customer_CashbackBalances_R5
			SELECT	cu.FanID
				,	CurrentCashbackAvailable = cu.CashbackAvailable
				,	PreviousCashbackAvailable = COALESCE(cb.CashbackAvailable, 0)
			INTO #Customer_CashbackBalances_R5
			FROM [Derived].[Customer] cu
			OUTER APPLY (	SELECT	TOP(1)
									cb.FanID
								,	cb.CashbackAvailable
							FROM [Derived].[Customer_CashbackBalances] cb
							WHERE cu.FanID = cb.FanID
							AND cb.Date < @Today_FivePoundBalance
							ORDER BY	cb.Date DESC) cb
			WHERE 5 <= cu.CashbackAvailable
			AND COALESCE(cb.CashbackAvailable, 0) < 5

		/***************************************************************************************************************************************
			5.2.	Load new £5 Balance customers to permanent table
		***************************************************************************************************************************************/

			INSERT INTO [Derived].[Customer_Reach5GBPDate] (FanID
														,	CashbackAvailable
														,	PreviousCashbackAvailable
														,	Reach5GBPDate)
			SELECT	FanID = cb.FanID
				,	CashbackAvailable = cb.CurrentCashbackAvailable
				,	PreviousCashbackAvailable = cb.PreviousCashbackAvailable
				,	Reach5GBPDate = @Today_FivePoundBalance
			FROM #Customer_CashbackBalances_R5 cb
			WHERE NOT EXISTS (	SELECT 1
								FROM [Derived].[Customer_Reach5GBPDate] r5
								WHERE cb.FanID = r5.FanID)

		/***************************************************************************************************************************************
			5.3.	Fetch £5 Balance customers from permanent table
					Taken from permament table rather than temp table to avoid missing customers if process is ran multiple times in one day
		***************************************************************************************************************************************/
				
			IF OBJECT_ID('tempdb..#5PoundBalanceEmailCustomers') IS NOT NULL DROP TABLE #5PoundBalanceEmailCustomers
			SELECT	r5.FanID
				,	r5.Reach5GBPDate
			INTO #5PoundBalanceEmailCustomers
			FROM [Derived].[Customer_Reach5GBPDate] r5
			WHERE Reach5GBPDate = @Today_FivePoundBalance
		

	/*******************************************************************************************************************************************
		6.	Fetch Redemption Reminder - Value email customers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			6.1.	Create Table Of All currently live Redemption Reminder - Value trigger emails
		***************************************************************************************************************************************/
	 			
			-- CashbackValue is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
			IF OBJECT_ID('tempdb..#RedemptionReminder_Value') IS NOT NULL DROP TABLE #RedemptionReminder_Value
			SELECT	tec.ID AS TriggerEmailTypeID
				,	CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS CashbackValue
			INTO #RedemptionReminder_Value
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT	te.ID
								,	te.TriggerEmail
								,	SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE tec.ID = te.ID) te1
			CROSS APPLY (	SELECT	te.ID
								,	LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE te1.ID = te.ID) te2
			WHERE tec.TriggerEmail LIKE '%Redemption%Cashback%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Value (CashbackValue)

		/***************************************************************************************************************************************
			6.2.	Fetch customers current & previous Cashback Available balance
		***************************************************************************************************************************************/

			DECLARE @Today_RedemptionReminderValue DATE = GETDATE()

			IF OBJECT_ID('tempdb..#Customer_CashbackBalances_RRV') IS NOT NULL DROP TABLE #Customer_CashbackBalances_RRV
			SELECT	cu.FanID
				,	CurrentCashbackAvailable = cu.CashbackAvailable
				,	PreviousCashbackAvailable = COALESCE(cb.CashbackAvailable, 0)
			INTO #Customer_CashbackBalances_RRV
			FROM [Derived].[Customer] cu
			OUTER APPLY (	SELECT	TOP(1)
									cb.FanID
								,	cb.CashbackAvailable
							FROM [Derived].[Customer_CashbackBalances] cb
							WHERE cu.FanID = cb.FanID
							AND cb.Date < @Today_RedemptionReminderValue
							ORDER BY	cb.Date DESC) cb

			CREATE CLUSTERED INDEX CIX_CashbackAvailable ON #Customer_CashbackBalances_RRV (FanID, CurrentCashbackAvailable, PreviousCashbackAvailable)

		/***************************************************************************************************************************************
			6.3.	Fetch the maximum possible cashback that each customer quailifies for, where they wouldn't have qualified the previous day
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#RedemptionReminder_ValueEmailCustomers') IS NOT NULL DROP TABLE #RedemptionReminder_ValueEmailCustomers
			SELECT	cb.FanID
				,	cb.CurrentCashbackAvailable
				,	MAX(rrv.CashbackValue) AS CashbackValue
			INTO #RedemptionReminder_ValueEmailCustomers
			FROM #Customer_CashbackBalances_RRV cb
			CROSS JOIN #RedemptionReminder_Value rrv
			WHERE rrv.CashbackValue <= cb.CurrentCashbackAvailable
			AND cb.PreviousCashbackAvailable < cb.CurrentCashbackAvailable
			AND cb.PreviousCashbackAvailable < rrv.CashbackValue
			GROUP BY	cb.FanID
					,	cb.CurrentCashbackAvailable

			CREATE CLUSTERED INDEX CIX_FanID ON #RedemptionReminder_ValueEmailCustomers (FanID)
		

	/*******************************************************************************************************************************************
		7.	Fetch Redemption Reminder - Days email customers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			7.1.	Create Table Of All currently live Redemption Reminder - Days trigger emails
		***************************************************************************************************************************************/
		
			-- DaysSinceEmail is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
			IF OBJECT_ID('tempdb..#RedemptionReminder_Days') IS NOT NULL DROP TABLE #RedemptionReminder_Days
			SELECT tec.ID AS TriggerEmailTypeID
				 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS DaysSinceEmail
			INTO #RedemptionReminder_Days
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT	te.ID
								,	te.TriggerEmail
								,	SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE tec.ID = te.ID) te1
			CROSS APPLY (	SELECT	te.ID
								,	LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE te1.ID = te.ID) te2
			WHERE tec.TriggerEmail LIKE '%Redemption%Days%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Days (DaysSinceEmail)

		/***************************************************************************************************************************************
			7.2.	Find customers who Received their '£5 Earnt' email x days ago
		***************************************************************************************************************************************/

			DECLARE @Today_RedemptionReminderDays DATE = GETDATE()

			IF OBJECT_ID('tempdb..#RedemptionReminder_DaysEmailCustomers') IS NOT NULL DROP TABLE #RedemptionReminder_DaysEmailCustomers
			SELECT	cu.FanID
				,	cu.SourceUID
				,	tec.EmailSendDate
				,	rrd.DaysSinceEmail
			INTO #RedemptionReminder_DaysEmailCustomers
			FROM [Email].[TriggerEmailCustomers] tec
			INNER JOIN #Customer cu
				ON tec.FanID = cu.FanID
			INNER JOIN #RedemptionReminder_Days rrd
				ON DATEDIFF(DAY, tec.EmailSendDate, @Today_RedemptionReminderDays) = rrd.DaysSinceEmail
			WHERE tec.TriggerEmailTypeID = 2

			CREATE CLUSTERED INDEX CIX_SourceUID ON #RedemptionReminder_DaysEmailCustomers (SourceUID)

		/***************************************************************************************************************************************
			7.3.	Fetch the lastest redemption date for all customers fetched in the previous step
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#RedemptionReminder_DaysRedemptions') IS NOT NULL DROP TABLE #RedemptionReminder_DaysRedemptions
			SELECT re.CustomerID
				 , MAX(re.RedemptionDate) AS RedemptionDate
			INTO #RedemptionReminder_DaysRedemptions        
			FROM [Inbound].[Redemptions] re
			WHERE EXISTS (	SELECT 1
							FROM #RedemptionReminder_DaysEmailCustomers rrdc
							WHERE re.CustomerID = rrdc.SourceUID)
			GROUP BY re.CustomerID

			CREATE CLUSTERED INDEX CIX_SourceUID ON #RedemptionReminder_DaysRedemptions (CustomerID)

		/***************************************************************************************************************************************
			7.4.	Remove customers that redeemed since their '£5 Earnt' email, leaving only customers who qualify for the email
		***************************************************************************************************************************************/

			DELETE rrdc
			FROM #RedemptionReminder_DaysEmailCustomers rrdc
			INNER JOIN #RedemptionReminder_DaysRedemptions rrdr
				ON rrdc.FanID = rrdr.CustomerID
			WHERE rrdc.EmailSendDate < rrdr.RedemptionDate
		

	/*******************************************************************************************************************************************
		8.	Truncate final table and populate with all fields
	*******************************************************************************************************************************************/
	
		BEGIN TRAN	--	Delta Processing

		/***************************************************************************************************************************************
			8.1.	If the Daily Calcs haven't already run today, Truncate yesterdays table and copy data from todays table, before updates are made
		***************************************************************************************************************************************/

			DECLARE @Today_DailyDataLog DATE = GETDATE()
				,	@DailyDataLogEntriesForToday INT

			SELECT @DailyDataLogEntriesForToday = COUNT(*)
			FROM [Email].[EmailDailyDataLog]
			WHERE CONVERT(DATE, CompletionDate) = @Today_DailyDataLog

			--IF @DailyDataLogEntriesForToday = 0
			--	BEGIN

			--		TRUNCATE TABLE [Email].[DailyData_PreviousDay]

			--		INSERT INTO [Email].[DailyData_PreviousDay]
			--		SELECT * 
			--		FROM [Email].[DailyData]

			--	END

		/***************************************************************************************************************************************
			8.2.	Truncate final table and populate with all fields 
		***************************************************************************************************************************************/
	
			IF OBJECT_ID('tempdb..#Balances') IS NOT NULL DROP TABLE #Balances
			select	cu.fanId
				,	MAX(CONVERT(DECIMAL(19, 2), ba.cleared)) AS cleared
				,	MAX(CONVERT(DECIMAL(19, 2), ba.pending)) AS pending
				,	MAX(CONVERT(DECIMAL(19, 2), ba.lifetime)) AS lifetime
			INTO #Balances
			from staging.inbound_customers_fullrefresh cu
			INNER JOIN staging.[balances-2021-02-12_100412] ba
				ON cu.rewardCustomerId = ba.hashKey
			INNER JOIN #Customer c
				ON cu.slcCustomerId = c.SourceUID
			GROUP BY cu.fanId

			TRUNCATE TABLE [Email].[DailyData]

			INSERT INTO [Email].[DailyData] (FanID
										   , Email
										   , PublisherID
										   , CustomerSegment
										   , Title
										   , FirstName
										   , LastName
										   , DOB
										   , CashbackAvailable
										   , CashbackPending
										   , CashbackLTV
										   , PartialPostCode
										   , Marketable
										   , Birthday_Flag
										   , Birthday_Code
										   , Birthday_CodeExpiryDate
										   , FirstEarn_Date
										   , FirstEarn_Amount
										   , FirstEarn_RetailerName
										   , FirstEarn_Type
										   , Reached5GBP_Date
										   , RedeemReminder_Amount
										   , RedeemReminder_Day
										   , EarnConfirmation_Date)
			SELECT cu.FanID
				 , cu.Email
				 , cu.ClubID AS PublisherID
				 , CustomerSegment = COALESCE(cs.CustomerSegment, '')
				 , Title = COALESCE(cu.Title, '')
				 , cu.FirstName
				 , cu.LastName
				 , cu.DOB
				 , COALESCE(ba.cleared, cu.CashbackAvailable) AS CashbackAvailable
				 , COALESCE(ba.pending, cu.CashbackPending) AS CashbackPending
				 , COALESCE(ba.lifetime, cu.CashbackLTV) AS CashbackLTV
				 , PartialPostCode = cu.PostCodeDistrict
				 , Marketable = cu.MarketableByEmail
				 , Birthday_Flag = COALESCE(bc.Birthday_Flag, '')
				 , Birthday_Code = COALESCE(bc.Birthday_Code, '')
				 , Birthday_CodeExpiryDate = COALESCE(bc.Birthday_CodeExpiryDate, '')
				 , FirstEarn_Date = COALESCE(pos.TranDate, '')
				 , FirstEarn_Amount = COALESCE(pos.CashbackAmount, '')
				 , FirstEarn_RetailerName = COALESCE(pos.PartnerName, '')
				 , FirstEarn_Type = COALESCE(pos.FirstEarn_Type, '')
				 , Reached5GBP_Date = COALESCE(fp.Reach5GBPDate, '')
				 , RedeemReminder_Amount = COALESCE(rrvc.CashbackValue, '')
				 , RedeemReminder_Day = COALESCE(rrdc.DaysSinceEmail, '')
				 , EarnConfirmation_Date = COALESCE(ec.EarnConfirmation_Date, '')
			FROM #Customer cu
			LEFT JOIN #CustomerSegment cs
				ON cu.FanID = cs.FanID
			LEFT JOIN #BirthdayEmailCustomers bc
				ON cu.FanID = bc.FanID
				AND cu.MarketableByEmail = 1
			LEFT JOIN #FirstEarnPOSEmailCustomers pos
				ON cu.FanID = pos.FanID
				AND cu.MarketableByEmail = 1
			LEFT JOIN #5PoundBalanceEmailCustomers fp
				ON cu.FanID = fp.FanID
				AND cu.MarketableByEmail = 1
			LEFT JOIN #RedemptionReminder_ValueEmailCustomers rrvc
				ON cu.FanID = rrvc.FanID
				AND cu.MarketableByEmail = 1
			LEFT JOIN #RedemptionReminder_DaysEmailCustomers rrdc
				ON cu.FanID = rrdc.FanID
				AND cu.MarketableByEmail = 1
			LEFT JOIN #EarnConfirmationEmailCustomers ec
				ON cu.FanID = ec.FanID
			LEFT JOIN #Balances ba
				ON cu.FanID = ba.fanId
			WHERE cu.CurrentlyActive = 1



		/***************************************************************************************************************************************
			8.3.	Calculate Delta records
		***************************************************************************************************************************************/

			TRUNCATE TABLE [Email].[Actito_Deltas]
		
			INSERT INTO [Email].[Actito_Deltas]	
			SELECT * 
			FROM [Email].[DailyData]
			EXCEPT 
			SELECT * 
			FROM [Email].[DailyData_PreviousDay]

		COMMIT TRAN	--	Delta Processing


	EXEC [Monitor].[ProcessLog_Insert] @StoredProcedureName, 'Finished'


	INSERT INTO [Email].[EmailDailyDataLog]
	SELECT GETDATE()
	
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