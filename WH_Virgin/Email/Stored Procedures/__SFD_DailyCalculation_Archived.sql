

CREATE PROCEDURE [Email].[__SFD_DailyCalculation_Archived]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	EXEC [Monitor].[ProcessLog_Insert] 'SFD_DailyCalculation', 'Started'

	--	Fetch all active customers

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

	--	Fetch customer segments

		IF OBJECT_ID('tempdb..#CustomerSegment') IS NOT NULL DROP TABLE #CustomerSegment
		SELECT ls.FanID
			 , ls.CustomerSegment
		INTO #CustomerSegment
		FROM [Derived].[Customer_LoyaltySegment] ls
		WHERE ls.EndDate IS NULL
		AND EXISTS (SELECT 1
					FROM #Customer cu
					WHERE ls.FanID = cu.FanID)

		CREATE CLUSTERED INDEX CIX_FanID ON #CustomerSegment (FanID)

	--	Declare variables

		DECLARE @Today DATE = GETDATE()
			  , @Yesterday DATE = DATEADD(DAY, -1, GETDATE())
	  
	--	Fetch customer birthday details

		IF OBJECT_ID('tempdb..#BirthdayCustomer') IS NOT NULL DROP TABLE #BirthdayCustomer
		SELECT cu.FanID
			 , 1 AS Birthday_Flag
			 , CONVERT(NVARCHAR(255), NULL) AS Birthday_Code
			 , CONVERT(DATE, NULL) AS Birthday_CodeExpiryDate
		INTO #BirthdayCustomer
		FROM #Customer cu
		WHERE DATEPART(MONTH, @Today) = DATEPART(MONTH, cu.DOB)
		AND DATEPART(DAY, @Today) = DATEPART(DAY, cu.DOB)
		AND cu.CurrentlyActive = 1

		CREATE CLUSTERED INDEX CIX_FanID ON #BirthdayCustomer (FanID)

		/*

		Update for Birthday Code details

		*/

	--	Fetch Earn Confirmation, First Earn (POS) & Reached 5 Pound Balance

		--	Fetch subset of trans covering all transactions that have been procssed the previous day

			IF OBJECT_ID('tempdb..#TransTemp') IS NOT NULL DROP TABLE #TransTemp
			SELECT TOP 10000000 *
			INTO #TransTemp
			FROM [Inbound].[Transactions] tr
			ORDER BY LoadDate DESC

			IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
			SELECT	tr.*
				,	cu.FanID
			INTO #Trans
			FROM #TransTemp tr
			INNER JOIN [WHB].[Inbound_Cards] ca
				ON tr.CardID = ca.CardID
			INNER JOIN #Customer cu
				ON cu.SourceUID = ca.PrimaryCustomerID
			WHERE CONVERT(DATE, tr.LoadDate) = @Yesterday
			AND 0 < tr.CashbackAmount
			ORDER BY LoadDate DESC
		
			DROP TABLE WH_Virgin.Derived.Customer_FirstEarnDate
			CREATE TABLE WH_Virgin.Derived.Customer_FirstEarnDate (	ID INT IDENTITY
																,	FanID BIGINT
																,	CardID UNIQUEIDENTIFIER
																,	TranDate DATETIME2(0)
																,	LoadDate DATETIME2(0)
																,	PartnerID INT
																,	PartnerName VARCHAR(50)
																,	CashbackAmount MONEY)

		--	Fetch Earn Confirmation customers
		
			--	Fetch all customers who have earnt on a transaction the previous day

				IF OBJECT_ID('tempdb..#EarnConfirmation') IS NOT NULL DROP TABLE #EarnConfirmation
				SELECT	DISTINCT
						tr.FanID
					  , @Yesterday AS EarnConfirmation_Date
				INTO #EarnConfirmation
				FROM #Trans tr

				CREATE CLUSTERED INDEX CIX_FanID ON #EarnConfirmation (FanID)

		--	Fetch First Earn POS customers

			--	Of customers that earnt yesterday, fetch those who have had a previous incentivised POS transaction

				IF OBJECT_ID('tempdb..#FirstTrans') IS NOT NULL DROP TABLE #FirstTrans
				SELECT	tr.FanID
					,	tr.CardID
					,	CONVERT(DATETIME, tr.TransactionDate) + CONVERT(DATETIME, tr.TransactionTime) AS TranDate
					,	tr.LoadDate
					,	tr.CashbackAmount
					,	pa.ID AS PartnerID
					,	pa.Name AS PartnerName
					,	ROW_NUMBER() OVER (PARTITION BY tr.FanID ORDER BY tr.LoadDate, CONVERT(DATETIME, tr.TransactionDate) + CONVERT(DATETIME, tr.TransactionTime), tr.CardID, tr.CashbackAmount) AS TransactionNumber
				INTO #FirstTrans
				FROM #Trans tr
				INNER JOIN [SLC_REPL].[dbo].[IronOffer] iof
					ON tr.OfferID = iof.ID
				INNER JOIN [Warehouse].[iron].[PrimaryRetailerIdentification] pri
					ON iof.PartnerID = pri.PartnerID
				INNER JOIN [SLC_REPL].[dbo].[Partner] pa
					ON COALESCE(pri.PrimaryPartnerID, pri.PartnerID) = pa.ID
				WHERE NOT EXISTS (	SELECT 1
									FROM [Derived].[Customer_FirstEarnDate] fed
									WHERE tr.FanID = fed.FanID)

			--	For all customers who had their first transaction processed yesterday, find the first date and the first transaction on that date


				INSERT INTO [Derived].[Customer_FirstEarnDate]
				SELECT	ft.FanID
					,	ft.CardID
					,	ft.TranDate
					,	ft.LoadDate
					,	ft.CashbackAmount
					,	ft.PartnerID
					,	ft.PartnerName
				FROM #FirstTrans ft
				WHERE TransactionNumber = 1


			--	Fetch the first transaction per customer and details of that transaction
				
				IF OBJECT_ID('tempdb..#FirstEarnPOS') IS NOT NULL DROP TABLE #FirstEarnPOS
				SELECT	ft.FanID
					,	ft.PartnerName
					,	ft.TranDate
					,	ft.CashbackAmount
					,	'POS' AS FirstEarn_Type
				INTO #FirstEarnPOS
				FROM #FirstTrans ft
				WHERE TransactionNumber = 1

	--	Fetch customers who have reached a £5 total cashback lifetime value for the first time, where they haven't already received an email

		IF OBJECT_ID('tempdb..#CashbackLTV') IS NOT NULL DROP TABLE #CashbackLTV
		SELECT	cu.FanID
			,	cb.CashbackLTV
		INTO #CashbackLTV
		FROM [Derived].[Customer] cu
		CROSS APPLY (	SELECT	TOP(1)
								cb.FanID
							,	cb.CashbackLTV
						FROM [Derived].[Customer_CashbackBalances] cb
						WHERE cu.FanID = cb.FanID
						ORDER BY	cb.Date DESC) cb

		CREATE CLUSTERED INDEX CIX_CashbackValue ON #CashbackLTV (FanID, CashbackLTV)

		IF OBJECT_ID('tempdb..#5PoundBalance') IS NOT NULL DROP TABLE #5PoundBalance
		SELECT	cu.FanID
			,	@Today AS Earn5PoundDate
		INTO #5PoundBalance
		FROM [Derived].[Customer] cu
		LEFT JOIN #CashbackLTV cb
			ON cu.FanID = cb.FanID
		WHERE 5 <= cu.CashbackLTV
		AND COALESCE(cb.CashbackLTV, 0) < 5
		AND NOT EXISTS (SELECT 1
						FROM [Email].[TriggerEmailCustomers] tec
						WHERE cu.FanID = tec.FanID
						AND tec.TriggerEmailTypeID IN (2))
		GROUP BY cu.FanID

	  
	--	Redemption Reminder - Value

		--	Create Table Of All currently live Redemption Reminder - Value trigger emails
			
			-- CashbackValue is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
			IF OBJECT_ID('tempdb..#RedemptionReminder_Value') IS NOT NULL DROP TABLE #RedemptionReminder_Value
			SELECT	tec.ID AS TriggerEmailTypeID
				,	CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS CashbackValue
			INTO #RedemptionReminder_Value
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT te.ID
								 , te.TriggerEmail
								 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE tec.ID = te.ID) te1
			CROSS APPLY (	SELECT te.ID
								 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE te1.ID = te.ID) te2
			WHERE tec.TriggerEmail LIKE '%Redemption%Cashback%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Value (CashbackValue)

		--	Fetch the maximum possible cashback that each customer quailifies for, where they wouldn't have qualified the previous day

			IF OBJECT_ID('tempdb..#CashbackAvailable') IS NOT NULL DROP TABLE #CashbackAvailable
			SELECT	cu.FanID
				,	cb.CashbackAvailable
			INTO #CashbackAvailable
			FROM [Derived].[Customer] cu
			CROSS APPLY (	SELECT	TOP(1)
									cb.FanID
								,	cb.CashbackAvailable
							FROM [Derived].[Customer_CashbackBalances] cb
							WHERE cu.FanID = cb.FanID
							ORDER BY	cb.Date DESC) cb

			CREATE CLUSTERED INDEX CIX_CashbackAvailable ON #CashbackAvailable (FanID, CashbackAvailable)

			UPDATE #CashbackAvailable
			SET CashbackAvailable = CASE WHEN CashbackAvailable < 5 THEN 0 ELSE CashbackAvailable - 5 END
	
			IF OBJECT_ID('tempdb..#RedemptionReminder_ValueCustomers') IS NOT NULL DROP TABLE #RedemptionReminder_ValueCustomers
			SELECT cu.FanID
				 , cu.CashbackAvailable
				 , MAX(rrv.CashbackValue) AS CashbackValue
			INTO #RedemptionReminder_ValueCustomers
			FROM #Customer cu
			LEFT JOIN #CashbackAvailable ca
				ON cu.FanID = ca.FanID
			CROSS JOIN #RedemptionReminder_Value rrv
			WHERE rrv.CashbackValue <= cu.CashbackAvailable
			AND COALESCE(ca.CashbackAvailable, 0) < cu.CashbackAvailable
			GROUP BY cu.FanID
				   , cu.CashbackAvailable
			HAVING MAX(ca.CashbackAvailable) < MAX(rrv.CashbackValue)

			CREATE CLUSTERED INDEX CIX_FanID ON #RedemptionReminder_ValueCustomers (FanID)
  
	--	Redemption Reminder - Days
		
		--	Create Table Of All currently live Redemption Reminder - Value trigger emails
		
			-- DaysSinceEmail is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
			IF OBJECT_ID('tempdb..#RedemptionReminder_Days') IS NOT NULL DROP TABLE #RedemptionReminder_Days
			SELECT tec.ID AS TriggerEmailTypeID
				 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS DaysSinceEmail
			INTO #RedemptionReminder_Days
			FROM [Email].[TriggerEmailType] tec
			CROSS APPLY (	SELECT te.ID
								 , te.TriggerEmail
								 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE tec.ID = te.ID) te1
			CROSS APPLY (	SELECT te.ID
								 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
							FROM [Email].[TriggerEmailType] te
							WHERE te1.ID = te.ID) te2
			WHERE tec.TriggerEmail LIKE '%Redemption%Days%'
			AND tec.CurrentlyLive = 1

			CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Days (DaysSinceEmail)

		--	Find customers who Received their '£5 Earnt' email x days ago

			IF OBJECT_ID('tempdb..#RedemptionReminder_DaysCustomers') IS NOT NULL DROP TABLE #RedemptionReminder_DaysCustomers
			SELECT	cu.FanID
				,	cu.SourceUID
				,	tec.EmailSendDate
				,	rrd.DaysSinceEmail
			INTO #RedemptionReminder_DaysCustomers
			FROM [Email].[TriggerEmailCustomers] tec
			INNER JOIN #Customer cu
				ON tec.FanID = cu.FanID
			INNER JOIN #RedemptionReminder_Days rrd
				ON DATEDIFF(DAY, tec.EmailSendDate, @Today) = rrd.DaysSinceEmail
			WHERE tec.TriggerEmailTypeID = 2

			CREATE CLUSTERED INDEX CIX_SourceUID ON #RedemptionReminder_DaysCustomers (SourceUID)
							
		--	Fetch the lastest redemption date for all customers fetched in the previous step

			IF OBJECT_ID('tempdb..#RedemptionReminder_DaysRedemptions') IS NOT NULL DROP TABLE #RedemptionReminder_DaysRedemptions
			SELECT re.CustomerID
				 , MAX(re.RedemptionDate) AS RedemptionDate
			INTO #RedemptionReminder_DaysRedemptions        
			FROM [Inbound].[Redemptions] re
			WHERE EXISTS (	SELECT 1
							FROM #RedemptionReminder_DaysCustomers rrdc
							WHERE re.CustomerID = rrdc.SourceUID)
			GROUP BY re.CustomerID

			CREATE CLUSTERED INDEX CIX_SourceUID ON #RedemptionReminder_DaysRedemptions (CustomerID)

		--	Remove all customers that have made a redemption since their '£5 Earnt' email, leaving only customers who qualify for the email

			DELETE rrdc
			FROM #RedemptionReminder_DaysCustomers rrdc
			INNER JOIN #RedemptionReminder_DaysRedemptions rrdr
				ON rrdc.SourceUID = rrdr.CustomerID
			WHERE rrdc.EmailSendDate < rrdr.RedemptionDate
  
  
	--	Insert into the [Email].[DailyData] table

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
			 , cs.CustomerSegment
			 , cu.Title
			 , cu.FirstName
			 , cu.LastName
			 , cu.DOB
			 , cu.CashbackAvailable
			 , cu.CashbackPending
			 , cu.CashbackLTV
			 , cu.PostCodeDistrict AS PartialPostCode
			 , cu.MarketableByEmail AS Marketable
			 , bc.Birthday_Flag
			 , bc.Birthday_Code
			 , bc.Birthday_CodeExpiryDate
			 , pos.TranDate AS FirstEarn_Date
			 , pos.CashbackAmount AS FirstEarn_Amount
			 , pos.PartnerName AS FirstEarn_RetailerName
			 , pos.FirstEarn_Type
			 , fp.Earn5PoundDate AS Reached5GBP_Date
			 , rrvc.CashbackValue AS RedeemReminder_Amount
			 , rrdc.DaysSinceEmail AS RedeemReminder_Day
			 , ec.EarnConfirmation_Date
		FROM #Customer cu
		LEFT JOIN #CustomerSegment cs
			ON cu.FanID = cs.FanID
		LEFT JOIN #BirthdayCustomer bc
			ON cu.FanID = bc.FanID
			AND cu.MarketableByEmail = 1
		LEFT JOIN #FirstEarnPOS pos
			ON cu.FanID = pos.FanID
			AND cu.MarketableByEmail = 1
		LEFT JOIN #5PoundBalance fp
			ON cu.FanID = fp.FanID
			AND cu.MarketableByEmail = 1
		LEFT JOIN #RedemptionReminder_ValueCustomers rrvc
			ON cu.FanID = rrvc.FanID
			AND cu.MarketableByEmail = 1
		LEFT JOIN #RedemptionReminder_DaysCustomers rrdc
			ON cu.FanID = rrdc.FanID
			AND cu.MarketableByEmail = 1
		LEFT JOIN #EarnConfirmation ec
			ON cu.FanID = ec.FanID
		WHERE cu.CurrentlyActive = 1

	EXEC [Monitor].[ProcessLog_Insert] 'SFD_DailyCalculation', 'Finished'


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
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END