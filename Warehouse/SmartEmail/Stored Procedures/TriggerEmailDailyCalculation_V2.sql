

CREATE PROCEDURE [SmartEmail].[TriggerEmailDailyCalculation_V2] 
--WITH EXECUTE AS OWNER 
AS 
BEGIN

SET NOCOUNT ON



-- ********************************************************************************************************************UPDATE ME 

/********************************************************************************************
	Name: SmartEmail.TriggerEmailDailyCalculation
	Desc: CREATE the values for the daily file that CREATEs the values for the trigger emails
	Auth: Zoe Taylor

	Change History
			ZT 17/05/2018 - Stored procedure CREATEd
20180525 cjm changed 3-part name to 2-part name				
	
*********************************************************************************************/

	DECLARE @DATE DATE = GETDATE()
		  , @msg VARCHAR(MAX)
		  , @time DATETIME


	/******************************************************************		
			Calc Nominee Changes 
	******************************************************************/

		--EXEC [Staging].[SLC_Report_DailyLoad_CBP_ProcessDirectDebitStats_SFD_V2]
		--Exec [Staging].[SLC_Report_DailyLoad_NomineeChangeUPDATE


	/******************************************************************		
			Get full list of customers and calc Debit/Credit
	******************************************************************/
		IF OBJECT_ID('tempdb..#Fans') IS NOT NULL DROP TABLE #Fans
		CREATE TABLE #FANS (FanID INT NOT NULL
						  , CompositeID BIGINT NOT NULL 
						  , SourceUID VARCHAR(50) NULL
						  , ClubID INT NOT NULL
						  , ActivatedDate DATETIME NOT NULL
						  , LoyaltyAccount INT NULL
						  , IsLoyalty INT NULL
						  , IsCredit INT NULL
						  , IsDebit INT NULL
						  , ClubCashAvailable MONEY NULL
						  , ClubCashPending MONEY NULL
						  , Postcode VARCHAR(10) NULL
						  , Homemover INT NULL
						  , WelcomeEmailCode VARCHAR(10) NULL
						  , DateOfLastCard DATETIME NULL
						  , MyRewardAccount VARCHAR(50) NULL)

		INSERT INTO #Fans (FanID
						 , CompositeiD
						 , SourceUID
						 , ClubID
						 , ActivatedDate
						 , LoyaltyAccount
						 , IsLoyalty
						 , IsCredit
						 , IsDebit
						 , ClubCashAvailable
						 , ClubCashPending
						 , Postcode
						 , Homemover
						 , WelcomeEmailCode)
		SELECT f.ID AS FanID
			 , f.CompositeID
			 , SourceUID
			 , ClubID
			 , AgreedTCsDate AS ActivatedDate
			 , 0 AS LoyaltyAccount
			 , 0 AS IsLoyalty
			 , ISNULL(MAX(CASE
							WHEN PC.CardTypeID = 1 THEN 1
							ELSE 0
						  END) , 0) AS IsCredit
			 , ISNULL(MAX(CASE
							WHEN BO.FanID IS NOT NULL THEN 0
							WHEN PC.CardTypeID = 2 THEN 1
							ELSE 0
						  END), 0) AS IsDebit
			 , ClubCashAvailable
			 , ClubCashPending		
			 , f.Postcode
			 , 0 Homemover
			 , NULL AS WelcomeEmailCode
		FROM [SLC_Report].[dbo].[Fan] f WITH (NOLOCK)
		LEFT JOIN [SLC_Report].[dbo].[Pan] p WITH (NOLOCK) 
			ON p.CompositeID = f.CompositeID
			AND (P.RemovalDate IS NULL OR DATEDIFF(D, P.RemovalDate, GETDATE()) <= 14)
		LEFT JOIN [SLC_Report].[dbo].[PaymentCard] pc WITH (NOLOCK) 
			ON p.PaymentCardID = PC.ID
		LEFT JOIN [SLC_Report].[dbo].[BankProductOptOuts] bo WITH (NOLOCK) 
			ON p.UserID = BO.FanID
			AND BO.BankProductID = 1 
			AND BO.OptOutDate IS NOT NULL 
			AND BO.OptBackInDate IS NULL
		WHERE f.ClubID IN (132, 138)
		AND f.AgreedTCsDate IS NOT NULL
		AND f.[Status] = 1
		AND f.DeceasedDate IS NULL
		GROUP BY f.CompositeID
			   , f.ID
			   , f.SourceUID
			   , f.ClubID
			   , f.AgreedTCSDate
			   , ClubCashAvailable
			   , ClubCashPending
			   , f.Postcode

		CREATE CLUSTERED INDEX CIX_FanID ON #Fans (FanID)

	/******************************************************************		
			Find Loyalty Customers and SET Loyalty flags 
	******************************************************************/

		UPDATE f
		SET IsLoyalty = 1
		FROM #Fans f
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic WITH (NOLOCK)
			ON f.SourceUID = ic.SourceUID
			AND (CASE 
					WHEN f.ClubID = 132 THEN 2
					ELSE 1
				 End) = ic.IssuerID
		INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica WITH (NOLOCK)
			ON ic.ID = ica.IssuerCustomerID
			AND ica.EndDate IS NULL
		WHERE REPLACE(ica.[Value], ' ', '') = 'V'

	/******************************************************************		
			Calc Welcomes 
			- Calculates the Welcome code for a customer
			- W7 = Adding CC
			- W8 = CC Only
			 
			 W1 > First Credit, Existing Debit, Existing Customer
			 W2 > First Credit, Existing Debit, New Customer
			 W3 > First Credit, First Debit
			 W4 > First Credit, No Debit
			 W5 > Existing Credit, First Debit
			 W7 > First Credit, No Debit, Agreed T&Cs in last 2 days
			 W8 > First Credit
		
	******************************************************************/

		IF OBJECT_ID('tempdb..#WelcomeMembers') IS NOT NULL DROP TABLE #WelcomeMembers
		CREATE TABLE #WelcomeMembers (FanID INT NOT NULL PRIMARY KEY
									, RowNumber INT NOT NULL
									, NewCreditCardToday BIT NULL
									, HasCreditCardBefore BIT NULL
									, NewDebitCardToday BIT NULL
									, HasDebitCardBefore BIT NULL
									, ActivatedBeforeToday BIT NULL
									, LastAddedCard DATETIME NULL
									, WelcomeCode AS CASE 
									  					WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 1 THEN 'W1'
									  					WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 0 THEN 'W2'
									  					WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W3'
									  					WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 THEN 'W4'
									  					WHEN NewCreditCardToday = 0 AND HasCreditCardBefore = 1 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W5'
													 END)	

		DECLARE @ReportDate DATE = CAST(DATEADD(dd, -1, GETDATE()) AS DATE);

		;WITH
		Members AS (SELECT f.FanID AS FanID			
						 , CASE
								WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1
								ELSE 0
						   END AS NewCreditCardToday
						 , CASE
							 WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1
							 ELSE 0 
						   END AS HasCreditCardBefore
						 , CASE
							 WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1
							 ELSE 0 
						   END AS NewDebitCardToday
						 , CASE
							 WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1
							 ELSE 0 
						   END AS HasDebitCardBefore
						 , CASE
							 WHEN CONVERT(DATE, f.ActivatedDate) < @ReportDate THEN 1
							 ELSE 0 
						   END AS ActivatedBeforeToday
						 , p.AdditionDate
				   FROM #Fans AS F WITH (NOLOCK)
				   INNER JOIN [SLC_Report].[dbo].[Pan] P WITH (NOLOCK) 
					   ON P.CompositeID = f.CompositeID
				   INNER JOIN [SLC_Report].[dbo].[PaymentCard] PC WITH (NOLOCK) 
					   ON P.PaymentCardID = PC.ID)

		INSERT INTO #WelcomeMembers (FanID
								   , RowNumber
								   , NewCreditCardToday
								   , HasCreditCardBefore
								   , NewDebitCardToday
								   , HasDebitCardBefore
								   , ActivatedBeforeToday
								   , LastAddedCard)
		SELECT FanID
			 , ROW_NUMBER() OVER (ORDER BY FanID) AS RowNumber
			 , MAX(NewCreditCardToday) AS NewCreditCardToday
			 , MAX(HasCreditCardBefore) AS HasCreditCardBefore
			 , MAX(NewDebitCardToday) AS NewDebitCardToday
			 , MAX(HasDebitCardBefore) AS HasDebitCardBefore
			 , MAX(ActivatedBeforeToday) AS ActivatedBeforeToday
			 , MAX(AdditionDate)
		FROM Members
		GROUP BY FanID


		/*
		
			 W1 > First Credit, Existing Debit, Existing Customer
			 W2 > First Credit, Existing Debit, New Customer
			 W3 > First Credit, First Debit
			 W4 > First Credit, No Debit
			 W5 > Existing Credit, First Debit
			 W7 > First Credit, No Debit, Agreed T&Cs in last 2 days
			 W8 > First Credit
		
		*/

		UPDATE f 
		SET WelcomeEmailCode = (CASE
									WHEN w.WelcomeCode = 'W4' AND ActivatedDate >= CONVERT(DATE, DATEADD(dd, -2, GETDATE())) THEN 'W8'
									WHEN w.WelcomeCode IN ('W1','W2','W3','W4') THEN 'W7'
									ELSE w.WelcomeCode
								END)  
		  , DateOfLastCard = CONVERT(DATE, w.LastAddedCard)
		FROM #Fans f
		INNER JOIN #WelcomeMembers w 
			ON f.FanID = W.FanID

	/******************************************************************		
			 Calc Homemovers
			 -- Calculates the customers that have moved home
	******************************************************************/

		UPDATE f
		SET Homemover = 1 
		FROM #Fans f
		INNER JOIN [Relational].[Customer] c
			ON f.FanID = c.FanID
		WHERE LEFT(REPLACE(c.Postcode,' ',''), 6) != LEFT(REPLACE(f.Postcode,' ',''), 6) 
		AND LEN(c.postcode) >= 5 
		AND LEN(f.Postcode) >= 5

	/******************************************************************		
			Calc Reached 5GBP 
			-- Calculates those that have reached £5 cashback available
			-- Updated Redeem flag for Redemption Reminder emails
	******************************************************************/	

		DECLARE @Today DATE = GETDATE()

		INSERT INTO [Relational].[Customers_Reach5GBP]
		SELECT f.FanID AS FanID
			 , @Today AS Reached
			 , 0 AS Redeemed
		FROM #Fans f
		WHERE f.ClubCashAvailable >= 5
		AND NOT EXISTS (SELECT 1
						FROM [Relational].[Customers_Reach5GBP] c
						WHERE f.FanID = c.FanID)

		/*----------------------------------------------------------------		
		   		Find those that have redeemed and UPDATE flag 
				-- Redemption Reminder flag      
		------------------------------------------------------------------*/
		
			IF OBJECT_ID('tempdb..#Customers_Reach5GBP') IS NOT NULL DROP TABLE #Customers_Reach5GBP
			SELECT DISTINCT
				   t.FanID
			INTO #Customers_Reach5GBP
			FROM [SLC_Report].[dbo].[Trans] t WITH (NOLOCK)
			INNER JOIN [SLC_Report].[dbo].[RedeemAction] ra WITH (NOLOCK)
				ON t.ID = ra.TransID
				AND ra.Status IN (1, 6)
			WHERE t.TypeID = 3
			AND t.Points > 0
			AND EXISTS (SELECT 1
						FROM [SLC_Report].[dbo].[Redeem] r
						WHERE r.ID = t.ItemID)
			
			UPDATE c
			SET Redeemed = 1
			FROM [Relational].[Customers_Reach5GBP] c
			WHERE c.Redeemed = 0
			AND EXISTS (SELECT 1
						FROM #Customers_Reach5GBP cr5
						WHERE c.FanID = cr5.FanID)
			
	/******************************************************************		
			Calc FirstEarn 
			-- Calculates WHEN someone has earned for the first time 
	******************************************************************/	

		TRUNCATE TABLE [SmartEmail].[TriggerEmailDailyFile_FirstEarn_Calculation]
		INSERT INTO [SmartEmail].[TriggerEmailDailyFile_FirstEarn_Calculation]
		SELECT FanID
		FROM #Fans
		WHERE LoyaltyAccount = 1

		--EXEC [Staging].[SLC_Report_DailyLoad_FirstSpend_V2]
		--EXEC [Staging].[SLC_Report_DailyLoad_LoyaltyPhase2_V2]
	
		UPDATE f
		SET f.LoyaltyAccount = 1
		FROM #Fans f
		WHERE EXISTS (SELECT 1
					  FROM [Staging].[LoyaltyPhase2Customers] l
					  WHERE f.FanID = l.FanID)


		/*----------------------------------------------------------------		
				  Earned on DD Offer
		-----------------------------------------------------------------*/

			IF OBJECT_ID('tempdb..#FirstEarnDD') IS NOT NULL DROP TABLE #FirstEarnDD
			SELECT ID
				 , FanID
				 , FirstEarnValue
				 , FirstEarnDate
				 , BankAccountID
				 , AccountName
				 , RowNo
			INTO #FirstEarnDD
			FROM (SELECT ID
					   , FanID
					   , FirstEarnValue
					   , FirstEarnDate
					   , BankAccountID
					   , AccountName
					   , ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
				  FROM [Staging].[Customer_FirstEarnDDPhase2] fedd
				  WHERE fedd.FirstEarnDate = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))) a
			WHERE RowNo = 1

		/*----------------------------------------------------------------		
				  Pull through Not Earned on MY Rewards DD 
		-----------------------------------------------------------------*/

			IF OBJECT_ID('tempdb..#NotEarned') IS NOT NULL DROP TABLE #NotEarned
			SELECT FanID
				 , AccountNo AS Day65AccountNo
				 , REPLACE(a.AccountName, ' account', '') AS Day65AccountName
			INTO #NotEarned
			FROM (SELECT FanID
					   , AccountName
					   , AccountNo
					   , ROW_NUMBER() OVER (PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
				  FROM [Staging].[Customer_DDNotEarned]
				  WHERE ChangeDate = DATEADD(dd, -65, DATEDIFF(dd, 0, @Date))) a
			WHERE RowNo = 1
	
		/*----------------------------------------------------------------		
				 First Earn POS Calc
		-----------------------------------------------------------------*/

			IF OBJECT_ID('tempdb..#FirstEarn') IS NOT NULL DROP TABLE #FirstEarn
			SELECT a.FanID
				 , a.FirstEarnValue
				 , a.FirstEarnType
			INTO #FirstEarn
			FROM [Staging].[Customers_Passed0GBP] a
			WHERE a.[Date] = DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
			AND LEN(FirstEarnType) > 0
			AND NOT EXISTS (SELECT 1
							FROM [Staging].[Customer_FirstEarnDDPhase2] b
							WHERE a.FanID = b.FanID)

			UPDATE F
			SET MyRewardAccount = fedd.AccountName 
			FROM #Fans f
			INNER JOIN #FirstEarnDD fedd
				ON fedd.FanID = f.FanID

	/******************************************************************		
			Build LoyaltyPhase2 Tables
	******************************************************************/

		TRUNCATE Table [Staging].[SLC_Report_DailyLoad_Phase2DataFields]
		INSERT INTO [Staging].[SLC_Report_DailyLoad_Phase2DataFields] (FanID
																	 , IsLoyalty
																	 , LoyaltyAccount
																	 , MyRewardAccount)
		SELECT FanID
			 , IsLoyalty
			 , LoyaltyAccount
			 , '' AS MyRewardAccount
		FROM #Fans

	/******************************************************************		
			To make sure customers who are MyRewardsa accounts
			only are not ticked AS on trial
	******************************************************************/
	
		--	Exec [Staging].[SLC_Report_UPDATE_FanSFDDailyUploadData_DirectDebit]
		DECLARE @OfferDate DATE = GETDATE()

		-------------------------------------------------------------------------------------------------
		---------------------Find offers for Household bills - Ontrial and MyRewards---------------------
		-------------------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#Offers') IS NOT NULL DROP TABLE #Offers
			SELECT i.ID AS IronOfferID
				 , CASE
						WHEN i.StartDate < 'Oct 01, 2015' THEN 'OnTrial'
						ELSE 'MyRewards'
				   End AS MyRewards
				 , i.EndDate
			INTO #Offers
			FROM [SLC_Report].[dbo].[IronOffer] i
			INNER JOIN [SLC_Report].[dbo].[Partner] p
				ON i.PartnerID = p.ID
			WHERE P.Name LIKE '%Household%' 
			AND i.Name LIKE '%Base%'
			AND @OfferDate < i.EndDate


		-------------------------------------------------------------------------------------------------
		---------------------Find customers on MyRewards who are currently ontrial-----------------------
		-------------------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#MyRewardsCustomers') IS NOT NULL DROP TABLE #MyRewardsCustomers
			SELECT dd.FanID
			INTO #MyRewardsCustomers
			FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dd
			WHERE OnTrial = 1

		-------------------------------------------------------------------------------------------------
		-----------Find customers on both offers for Household bills - Ontrial and MyRewards-------------
		-------------------------------------------------------------------------------------------------

			IF OBJECT_ID('tempdb..#OnTrial') IS NOT NULL DROP TABLE #OnTrial
			SELECT FanID
			INTO #OnTrial 
			FROM #MyRewardsCustomers m
			INNER JOIN [SLC_Report].[dbo].[Fan] f
				ON m.FanID = f.ID
			INNER JOIN [SLC_Report].[dbo].[IronOfferMember] iom
				ON f.CompositeID = iom.CompositeID
			INNER JOIN #Offers o
				ON iom.IronOfferID = o.IronOfferID
			WHERE o.MyRewards = 'OnTrial'
			AND (@OfferDate < iom.EndDate OR iom.EndDate IS NULL)


		-------------------------------------------------------------------------------------------------
		-------------------------------SET Ontrial to zero if not on trial anymore-----------------------
		-------------------------------------------------------------------------------------------------		

			UPDATE dd
			SET OnTrial = 0
			FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dd
			INNER JOIN #MyRewardsCustomers mrc
				on dd.FanID = mrc.FanID
			WHERE NOT EXISTS (SELECT 1
							  FROM #OnTrial ot
							  WHERE dd.FanID = ot.FanID)


		-------------------------------------------------------------------------------------------------
		-------------------------Remove other account names from MyRewardAccount field-------------------
		-------------------------------------------------------------------------------------------------

			UPDATE p2d
			SET MyRewardAccount = ''
			FROM [Staging].[SLC_Report_DailyLoad_Phase2DataFields] p2d
			WHERE MyRewardAccount != ''
			AND MyRewardAccount NOT LIKE 'Reward%'


	/******************************************************************		
			Calc Product Monitoring 
			-- Calculates 60 day and 120 day product monitoring values
	******************************************************************/

		--Exec [Staging].[SLC_Report_DailyLoad_DirectDebit60days_V3]
		--Exec [Staging].[SLC_Report_DailyLoad_DirectDebit120days_V3]

			/*----------------------------------------------------------------		
					  Get list of bank account names for customers
			------------------------------------------------------------------*/

			IF OBJECT_ID('tempdb..#BankAccounts_Distinct') IS NOT NULL DROP TABLE #BankAccounts_Distinct;
			WITH
			BankAccount AS (SELECT fa.FanID
								 , dud.AccountName1 AS MyRewardAccount
							FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
							INNER JOIN #Fans fa
								ON dud.FanID = fa.FanID
							WHERE fa.LoyaltyAccount = 1
							AND fa.MyRewardAccount = ''
							AND dud.AccountName1 LIKE 'Reward%'
							UNION ALL
							SELECT fa.FanID
								 , dud.AccountName2 AS MyRewardAccount
							FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
							INNER JOIN #Fans fa
								on dud.FanID = fa.FanID
							WHERE fa.LoyaltyAccount = 1
							AND fa.MyRewardAccount = ''
							AND dud.AccountName2 LIKE 'Reward%'
							UNION ALL
							SELECT fa.FanID
								 , dud.AccountName3 AS MyRewardAccount
							FROM [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
							INNER JOIN #Fans fa
								on dud.FanID = fa.FanID
							WHERE fa.LoyaltyAccount = 1
							AND fa.MyRewardAccount = ''
							AND dud.AccountName3 LIKE 'Reward%')

			SELECT FanID
				 , REPLACE(ba.MyRewardAccount,' Account','') AS MyRewardAccount 
			INTO #BankAccounts_Distinct
			FROM (SELECT FanID
					   , MyRewardAccount
					   , ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY CASE
																	WHEN MyRewardAccount LIKE '%Black%' THEN 0
																	WHEN MyRewardAccount LIKE '%Plat%' THEN 1
																	WHEN MyRewardAccount LIKE '%Silve%' THEN 2
																	WHEN MyRewardAccount LIKE '%Reward%' THEN 3
																	ELSE 4
																 END ASC) AS RowNo
				  FROM BankAccount) ba
			WHERE RowNo = 1

			/*----------------------------------------------------------------		
					UPDATE MyRewardAccount name field
			------------------------------------------------------------------*/
			
			UPDATE fa
			SET fa.MyRewardAccount = bad.MyRewardAccount
			FROM #Fans fa
			INNER JOIN  #BankAccounts_Distinct bad
				ON fa.FanID = bad.FanID
			WHERE LEN(fa.MyRewardAccount) = 0

	/******************************************************************		
					Calculate W&G Customer list for exclusion 
	******************************************************************/
			/*----------------------------------------------------------------		
					Find all accounts that are Williams & Glynn
			------------------------------------------------------------------*/

			IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts
			SELECT DISTINCT
				   ba.ID AS BankAccountID
			INTO #BankAccounts
			FROM [SLC_Report].[dbo].[BankAccount] ba
			WHERE COALESCE(ba.[Status], 1) = 1
			AND EXISTS (SELECT 1
						FROM [Staging].[WG_SortCodes] sc
						WHERE ba.SortCode = sc.SortCode)

			CREATE CLUSTERED INDEX ix_BankAccounts_BAID on #BankAccounts (BankAccountID)
			
			/*----------------------------------------------------------------		
					Find W&G customers for exclusion
			------------------------------------------------------------------*/	

			IF OBJECT_ID('tempdb..#CustomersWG') IS NOT NULL DROP TABLE #CustomersWG
			SELECT DISTINCT 
				   fa.FanID
				 , 1 AS WG
			INTO #CustomersWG
			FROM #BankAccounts ba
			INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
				ON ba.BankAccountID = iba.BankAccountID
				AND COALESCE(iba.CustomerStatus, 1) = 1
			INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
				ON iba.IssuerCustomerID = ic.ID
			INNER JOIN #Fans fa
				ON ic.SourceUID = fa.SourceUID 
				AND ic.IssuerID = (CASE WHEN ClubID = 132 THEN 2 ELSE 1 END)

	/******************************************************************		
			Final data SET 
	******************************************************************/

		TRUNCATE TABLE [SmartEmail].[TriggerEmailDailyFile_Calculated]
		INSERT INTO [SmartEmail].[TriggerEmailDailyFile_Calculated] (FanID
																   , LoyaltyAccount
																   , IsLoyalty
																   , IsDebit
																   , IsCredit
																   , WG
																   , FirstEarnDate
																   , FirstEarnType
																   , FirstEarnValue
																   , Reached5GBP
																   , Day65AccountName
																   , Day65AccountNo
																   , MyRewardAccount
																   , Homemover
																   , WelcomeEmailCode)
		SELECT fa.FanID
			 , fa.LoyaltyAccount
			 , fa.IsLoyalty
			 , fa.IsDebit
			 , fa.IsCredit
			 , COALESCE(wg.WG, 0) AS WG
			 , CASE
			 		WHEN fed.FirstEarnDate IS NOT NULL THEN fed.FirstEarnDate
			 		WHEN fe.FanID IS NOT NULL THEN DATEADD(dd, -1, DATEDIFF(dd, 0, @Date))
			 		ELSE '1900-01-01' 
			   END AS FirstEarnDate
			 , CASE
					WHEN fed.FanID IS NOT NULL THEN 'direct debit frontbook'
			 		ELSE COALESCE(fe.FirstEarnType, '')
			   END AS FirstEarnType
			 , COALESCE(fed.FirstEarnValue, fe.FirstEarnValue,0) AS FirstEarnValue
			 , COALESCE(Reached, '1900-01-01') AS Reached5GBP
			 , COALESCE(ne.Day65AccountName, '') AS Day65AccountName
			 , COALESCE(ne.Day65AccountNo, '') AS Day65AccountNo
			 , COALESCE(fed.AccountName, '') AS MyRewardAccount	
			 , fa.Homemover
			 , fa.WelcomeEmailCode
		FROM #Fans fa
		LEFT JOIN #CustomersWG wg
			ON fa.FanID = WG.FanID
		LEFT JOIN [Staging].[Customers_Passed0GBP] cp0
			ON fa.FanID = cp0.FanID
			AND cp0.Date = @Date
		LEFT JOIN #FirstEarnDD fed
			ON fa.FanID = fed.FanID
		LEFT JOIN #FirstEarn fe
			ON fa.FanID = fe.FanID
		LEFT JOIN [Relational].[Customers_Reach5GBP] cr5
			ON fa.FanID = cr5.FanID
			AND cr5.Redeemed = 0
		LEFT JOIN #NotEarned ne
			ON fa.FanID = ne.FanID


END






