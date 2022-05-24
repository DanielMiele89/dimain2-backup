
CREATE PROCEDURE [WHB].[Actito_DailyCalculation]
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
			,	cu.CustomerGUID
			,	cu.SourceUID
			,	cu.ClubID
			,	cu.Title
			,	cup.FirstName
			,	cup.LastName
			,	cup.Email
			,	cup.DOB
			,	cu.MarketableByEmail
			,	cu.EmailTracking
			,	cu.PostCodeDistrict
			,	cu.CashbackAvailable
			,	cu.CashbackPending
			,	cu.CashbackLTV
			,	cu.EmailStructureValid
			,	cu.CurrentlyActive
			,	cu.RegistrationDate
		INTO #Customer
		FROM [Derived].[Customer] cu
		INNER JOIN [Derived].[Customer_PII] cup
			ON cu.FanID = cup.FanID

		CREATE CLUSTERED INDEX CIX_FanID ON #Customer (FanID)

		UPDATE #Customer
		SET Email = 'VisaClosedAccount@RewardInsight.com'
		,	Title = ''
		,	FirstName = ''
		,	LastName = ''
		,	DOB = '1900-01-01'
		,	PostCodeDistrict = ''
		,	MarketableByEmail = 0
		,	EmailTracking = 0
		WHERE CurrentlyActive = 0

		UPDATE #Customer
		SET Email = 'VisaInvalidEmail@RewardInsight.com'
		WHERE EmailStructureValid = 0


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
		FROM [Inbound].[MatchedTransactions] mt
		INNER JOIN #Customer cu
			ON mt.CustomerGUID = cu.CustomerGUID
		WHERE 0 < mt.CashbackEarned
		AND CONVERT(DATE, mt.LoadDate) = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
		AND 1 = 2

		CREATE CLUSTERED INDEX CIX_FanID ON #EarnConfirmationEmailCustomers (FanID)
		

	/*******************************************************************************************************************************************
		4.	Fetch First Earn (POS) email customers (First earn through retailer offer)
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			4.1.	Fetch subset of trans covering all transactions that have been procssed the previous day
		***************************************************************************************************************************************/

			IF OBJECT_ID('tempdb..#FirstEarnTransTemp') IS NOT NULL DROP TABLE #FirstEarnTransTemp
			SELECT	TOP 10000000
					mt.CustomerGUID
				,	mt.CardGUID AS CardID
				,	mt.CashbackEarned AS CashbackAmount
				,	mt.TransactionDate
				,	mt.OfferGUID
				,	mt.FileName
				,	mt.LoadDate
			INTO #FirstEarnTransTemp
			FROM [Inbound].[MatchedTransactions] mt
			WHERE 0 < mt.CashbackEarned
			ORDER BY LoadDate DESC
			
			CREATE CLUSTERED INDEX CIX_CustomerGUID ON #FirstEarnTransTemp (CustomerGUID)

			IF OBJECT_ID('tempdb..#FirstEarnTrans') IS NOT NULL DROP TABLE #FirstEarnTrans;
			WITH
			FirstEarnTrans AS (	SELECT	tr.FileName
									,	tr.LoadDate
									,	cu.FanID
									,	tr.CardID
									,	tr.OfferGUID
									,	iof.IronOfferID AS OfferID
									,	PartnerID = pa.ID
									,	PartnerName = pa.Name
									,	tr.CashbackAmount
									,	TranDate = CONVERT(DATETIME, tr.TransactionDate)
									,	TransactionNumber = ROW_NUMBER() OVER (PARTITION BY cu.FanID ORDER BY CONVERT(DATETIME, tr.TransactionDate), tr.LoadDate, tr.CardID, tr.CashbackAmount)
								FROM #FirstEarnTransTemp tr
								INNER JOIN #Customer cu
									ON tr.CustomerGUID = cu.CustomerGUID
								INNER JOIN [Derived].[IronOffer] iof
									ON tr.OfferGUID = iof.HydraOfferID
								INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
									ON iof.PartnerID = pri.PartnerID
								INNER JOIN [SLC_REPL].[dbo].[Partner] pa
									ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID)
								

			SELECT	fet.FileName
				,	fet.LoadDate
				,	fet.FanID
				,	fet.CardID
				,	fet.OfferGUID
				,	fet.OfferID
				,	fet.PartnerID
				,	fet.PartnerName
				,	fet.CashbackAmount
				,	fet.TranDate
				,	fet.TransactionNumber
			INTO #FirstEarnTrans
			FROM FirstEarnTrans fet
			WHERE TransactionNumber = 1


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

			IF OBJECT_ID('tempdb..#FirstEarnPOSEmailCustomers') IS NOT NULL DROP TABLE #FirstEarnPOSEmailCustomers
			SELECT	fed.FanID
				,	fed.PartnerName
				,	TranDate = DATEADD(DAY, -1, CONVERT(DATE, fed.LoadDate))
				,	fed.CashbackAmount
				,	'POS' AS FirstEarn_Type
			INTO #FirstEarnPOSEmailCustomers
			FROM [Derived].[Customer_FirstEarnDate] fed
			WHERE EXISTS (	SELECT 1
							FROM #Customer cu
							WHERE fed.FanID = cu.FanID
							AND cu.MarketableByEmail = 1
							AND cu.EmailTracking = 1)

			IF (SELECT GETDATE()) < '2022-02-23'
				BEGIN

					UPDATE #FirstEarnPOSEmailCustomers
					SET TranDate = '2022-02-21'
					WHERE TranDate IN ('2022-02-18', '2022-02-19', '2022-02-20')

				END

	/*******************************************************************************************************************************************
		5.	Fetch Reached £5 Balance email customers (£5 first earn)
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			5.1.	Fetch customers who currently have £5 Cashback Available, but didn't in their most recent [Customer_CashbackBalances]
		***************************************************************************************************************************************/
		
			DECLARE @Today_FivePoundBalance DATE = GETDATE()
			DECLARE @Saturday_FivePoundBalance DATE = DATEADD(DAY, -2, GETDATE())

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
				,	@Today_FivePoundBalance AS Reach5GBPDate
			INTO #5PoundBalanceEmailCustomers
			FROM [Derived].[Customer_Reach5GBPDate] r5
			WHERE Reach5GBPDate = @Today_FivePoundBalance
			
			--IF DATENAME (dw , @Today_FivePoundBalance) = 'Monday'
			--	BEGIN

			--		--SET @Saturday_FivePoundBalance = '2021-05-29'

			--		INSERT INTO #5PoundBalanceEmailCustomers
			--		SELECT	r5.FanID
			--			,	@Today_FivePoundBalance AS Reach5GBPDate
			--		FROM [Derived].[Customer_Reach5GBPDate] r5
			--		WHERE Reach5GBPDate >= @Saturday_FivePoundBalance
			--		AND Reach5GBPDate < @Today_FivePoundBalance
			--		AND EXISTS (SELECT 1
			--					FROM [Derived].[Customer] cu
			--					WHERE r5.FanID = cu.FanID
			--					AND cu.CashbackAvailable >= 5)
													   
			--	END
						

	/*******************************************************************************************************************************************
		6.	Fetch Redemption Reminder - Value email customers
	*******************************************************************************************************************************************/

		/***************************************************************************************************************************************
			6.1.	Create Table Of All currently live Redemption Reminder - Value trigger emails
		***************************************************************************************************************************************/
	 			
			-- CashbackValue is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
			IF OBJECT_ID('tempdb..#RedemptionReminder_Value') IS NOT NULL DROP TABLE #RedemptionReminder_Value
			SELECT	tec.ID AS TriggerEmailTypeID
				,	CONVERT(INT, te1.TriggerEmail) AS CashbackValue
			INTO #RedemptionReminder_Value
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT	TriggerEmail = REPLACE(REPLACE(tec.TriggerEmail, 'Redemption Reminder - £', ''), ' Cashback', '')) te1
			WHERE tec.TriggerEmail LIKE '%Redemption%Cashback%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Value (CashbackValue)

		/***************************************************************************************************************************************
			6.2.	Fetch customers current & previous Cashback Available balance
		***************************************************************************************************************************************/
			
			DECLARE @Today_RedemptionReminderValue DATE = DATEADD(DAY, -0, GETDATE())
			
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
			SELECT	tec.ID AS TriggerEmailTypeID
				 , CONVERT(INT, te1.TriggerEmail) AS DaysSinceEmail
			INTO #RedemptionReminder_Days
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT	TriggerEmail = REPLACE(REPLACE(tec.TriggerEmail, 'Redemption Reminder - ', ''), ' Days', '')) te1
			WHERE tec.TriggerEmail LIKE '%Redemption%Days%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Days (DaysSinceEmail)

		/***************************************************************************************************************************************
			7.2.	Find customers who Received their '£5 Earnt' email x days ago
		***************************************************************************************************************************************/

			DECLARE @Today_RedemptionReminderDays DATE = GETDATE()

			IF OBJECT_ID('tempdb..#RedemptionReminder_DaysEmailCustomers') IS NOT NULL DROP TABLE #RedemptionReminder_DaysEmailCustomers
			SELECT	cu.FanID
				,	cu.CustomerGUID
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
			SELECT re.CustomerGUID
				 , MAX(re.RedeemedDate) AS RedemptionDate
			INTO #RedemptionReminder_DaysRedemptions        
			FROM [Inbound].[Redemptions] re
			WHERE EXISTS (	SELECT 1
							FROM #RedemptionReminder_DaysEmailCustomers rrdc
							WHERE re.CustomerGUID = rrdc.CustomerGUID)
			GROUP BY re.CustomerGUID

			CREATE CLUSTERED INDEX CIX_SourceUID ON #RedemptionReminder_DaysRedemptions (CustomerGUID)

		/***************************************************************************************************************************************
			7.4.	Remove customers that redeemed since their '£5 Earnt' email, leaving only customers who qualify for the email
		***************************************************************************************************************************************/

			DELETE rrdc
			FROM #RedemptionReminder_DaysEmailCustomers rrdc
			INNER JOIN #RedemptionReminder_DaysRedemptions rrdr
				ON rrdc.CustomerGUID = rrdr.CustomerGUID
			WHERE rrdc.EmailSendDate < rrdr.RedemptionDate
		

	/*******************************************************************************************************************************************
		8.	Fetch Birthday email customers
	*******************************************************************************************************************************************/
	
		DECLARE @Yesterday_Welcome DATE = DATEADD(DAY, -1, GETDATE())

		IF OBJECT_ID('tempdb..#WelcomeEmailCustomers') IS NOT NULL DROP TABLE #WelcomeEmailCustomers
		SELECT	cu.FanID
			,	'W' AS WelcomeCode
		INTO #WelcomeEmailCustomers
		FROM #Customer cu
		WHERE @Yesterday_Welcome = CONVERT(DATE, cu.RegistrationDate)
		AND cu.CurrentlyActive = 1

		CREATE CLUSTERED INDEX CIX_FanID ON #WelcomeEmailCustomers (FanID)
		

	/*******************************************************************************************************************************************
		9.	Truncate final table and populate with all fields
	*******************************************************************************************************************************************/
	
		BEGIN TRAN	--	Delta Processing

		/***************************************************************************************************************************************
			9.1.	If the Daily Calcs haven't already run today, Truncate yesterdays table and copy data from todays table, before updates are made
		***************************************************************************************************************************************/


			DECLARE @Today_DailyDataLog DATE = GETDATE()
				,	@DailyDataLogEntriesForToday INT
				,	@Weekday VARCHAR(15) = (SELECT DATENAME (dw , GETDATE()))

			SELECT @DailyDataLogEntriesForToday = COUNT(*)
			FROM [Email].[EmailDailyDataLog]
			WHERE CONVERT(DATE, CompletionDate) = @Today_DailyDataLog

			IF @DailyDataLogEntriesForToday = 0	-- AND DATENAME (dw , @Today_DailyDataLog) NOT IN ('Saturday', 'Sunday')
				BEGIN

					TRUNCATE TABLE [Email].[DailyData_PreviousDay]
					
					--IF DATENAME (dw , @Today_DailyDataLog) != 'Monday'
					--	BEGIN

							INSERT INTO [Email].[DailyData_PreviousDay]
							SELECT * 
							FROM [Email].[DailyData]

					--	END

				END

			   
		/***************************************************************************************************************************************
			9.2.	Truncate final table and populate with all fields 
		***************************************************************************************************************************************/

			TRUNCATE TABLE [Email].[DailyData]

			INSERT INTO [Email].[DailyData] (	FanID
											,	Email
											,	PublisherID
											,	CustomerSegment
											,	Title
											,	FirstName
											,	LastName
											,	DOB
											,	CashbackAvailable
											,	CashbackPending
											,	CashbackLTV
											,	PartialPostCode
											,	Marketable
											,	MarketableByEmail
											,	EmailTracking
											,	Birthday_Flag
											,	Birthday_Code
											,	Birthday_CodeExpiryDate
											,	FirstEarn_Date
											,	FirstEarn_Amount
											,	FirstEarn_RetailerName
											,	FirstEarn_Type
											,	Reached5GBP_Date
											,	RedeemReminder_Amount
											,	RedeemReminder_Day
											,	EarnConfirmation_Date)
			SELECT	FanID = cu.FanID
				,	Email = cu.Email
				,	PublisherID = cu.ClubID
				,	CustomerSegment = COALESCE(cs.CustomerSegment, '')
				,	Title = COALESCE(cu.Title, '')
				,	FirstName = cu.FirstName
				,	LastName = cu.LastName
				,	DOB = COALESCE(cu.DOB, '1900-01-01')
				,	CashbackAvailable = cu.CashbackAvailable
				,	CashbackPending = cu.CashbackPending
				,	CashbackLTV = cu.CashbackLTV
				,	PartialPostCode = cu.PostCodeDistrict
				,	Marketable =	CASE
										WHEN cu.MarketableByEmail = 1 AND cu.EmailTracking = 1 THEN 1
										ELSE 0
									END
				,	MarketableByEmail = cu.MarketableByEmail
				,	EmailTracking = cu.EmailTracking
				,	Birthday_Flag = COALESCE(bc.Birthday_Flag, '')
				,	Birthday_Code = COALESCE(bc.Birthday_Code, '')
				,	Birthday_CodeExpiryDate = COALESCE(bc.Birthday_CodeExpiryDate, '')
				,	FirstEarn_Date = COALESCE(pos.TranDate, '')
				,	FirstEarn_Amount = COALESCE(pos.CashbackAmount, '')
				,	FirstEarn_RetailerName = COALESCE(pos.PartnerName, '')
				,	FirstEarn_Type = COALESCE(pos.FirstEarn_Type, '')
				,	Reached5GBP_Date = COALESCE(fp.Reach5GBPDate, '')
				,	RedeemReminder_Amount = COALESCE(rrvc.CashbackValue, '')
				,	RedeemReminder_Day = COALESCE(rrdc.DaysSinceEmail, '')
				,	EarnConfirmation_Date = COALESCE(ec.EarnConfirmation_Date, '')
			FROM #Customer cu
			LEFT JOIN #CustomerSegment cs
				ON cu.FanID = cs.FanID
			LEFT JOIN #BirthdayEmailCustomers bc
				ON cu.FanID = bc.FanID
			LEFT JOIN #FirstEarnPOSEmailCustomers pos
				ON cu.FanID = pos.FanID
				AND cu.MarketableByEmail = 1
				AND cu.EmailTracking = 1
			LEFT JOIN #5PoundBalanceEmailCustomers fp
				ON cu.FanID = fp.FanID
				AND cu.MarketableByEmail = 1
				AND cu.EmailTracking = 1
			LEFT JOIN #RedemptionReminder_ValueEmailCustomers rrvc
				ON cu.FanID = rrvc.FanID
				AND cu.MarketableByEmail = 1
				AND cu.EmailTracking = 1
			LEFT JOIN #RedemptionReminder_DaysEmailCustomers rrdc
				ON cu.FanID = rrdc.FanID
				AND cu.MarketableByEmail = 1
				AND cu.EmailTracking = 1
			LEFT JOIN #EarnConfirmationEmailCustomers ec
				ON cu.FanID = ec.FanID
			--LEFT JOIN #WelcomeEmailCustomers wec
			--	ON cu.FanID = wec.FanID
			--	AND cu.MarketableByEmail = 1
			--	AND cu.EmailTracking = 1

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

			EXEC [Email].[Newsletter_DailyDataSampleCustomers_Populate]

		/***************************************************************************************************************************************
			8.4.	Record customers set to be uploaded to Actito
		***************************************************************************************************************************************/
			
			INSERT INTO [Email].[Actito_CustomersUploaded]
			SELECT	FanID
				,	AddedDate = CONVERT(DATE, GETDATE())
			FROM [Email].[DailyData] dd
			WHERE NOT EXISTS (	SELECT 1
								FROM [Email].[Actito_CustomersUploaded] acu
								WHERE dd.FanID = acu.FanID)
			AND NOT EXISTS (SELECT 1
							FROM [Email].[DailyData_PreviousDay] ddp
							WHERE dd.FanID = ddp.FanID
							AND dd.Email = ddp.Email)

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
