/*
		Author:		Rory Francis
		
		Date:		2019-04-26

		Purpose:	For those people that have had a MyReward account open 60 or 120 days and did not earn enough in the last calendar month

		UPDATE:		06-04-2017 SB - Amended to deal WITH new cashback rate and therefore they now only need to earn £2
								  - Also CONVERTed heaps to CLUSTERED INDEXed tables
*/

CREATE PROCEDURE [Staging].[SLC_Report_DailyLoad_ProductMonitoring_Retrosepctive] (@Days INT
																				, @IntendedSendDate DATE)
AS
BEGIN

----------------------------------------------------------------------------------------
-------------Find all current loyalty customers requiring resend------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Loyalty') IS NOT NULL DROP TABLE #Loyalty
	SELECT fa.ID AS FanID
		 , fa.CompositeID
		 , fa.SourceUID
		 , fa.ClubID
		 , fa.Email
		 , tec.SendDate
		 , tec.TriggerEmail
		 , COALESCE(tec.Day60AccountName, tec.Day120AccountName) AS AccountName
	INTO #Loyalty
	FROM [SLC_Report].[dbo].[Fan] fa
	INNER JOIN SmartEmail.DailyData_TriggerEmailCustomers tec
		ON fa.ID = tec.FanID
	WHERE TriggerEmail LIKE '%' + CONVERT(VARCHAR(3), @Days) + '%'
	AND TriggerEmail LIKE '%Product%'
	AND SendDate = @IntendedSendDate
	AND EXISTS (SELECT 1
				FROM [Staging].[SLC_Report_DailyLoad_Phase2DataFields] p2d
				WHERE p2d.LoyaltyAccount = 1
				AND p2d.FanID = fa.ID)

	DELETE l
	FROM #Loyalty l
	INNER JOIN SmartEmail.DailyData_TriggerEmailCustomers tec
		ON l.TriggerEmail = tec.TriggerEmail
		AND l.FanID = tec.FanID
		AND l.SendDate != tec.SendDate

	CREATE CLUSTERED INDEX CIX_Fan on #Loyalty (FanID)

----------------------------------------------------------------------------------------
-----------------------------Find Accounts and IronOfferIDs-----------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Accounts') IS NOT NULL DROP TABLE #Accounts
	SELECT BankAccountType
		 , IssuerID
		 , ClubID
		 , IronOfferID
	INTO #Accounts
	FROM [SLC_Report].[dbo].[BankAccountTypeEligibility] bate
	INNER JOIN [Staging].[DirectDebit_EligibleAccounts] dde
		ON bate.BankAccountType = dde.AccountType
		AND bate.IssuerID = (CASE WHEN dde.ClubID = 138 THEN 1 ELSE 2 END)
	WHERE bate.DirectDebitEligible = 1
	AND dde.LoyaltyFeeAccount = 1

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #Accounts (IronOfferID)

----------------------------------------------------------------------------------------
------------------------------find the typeID for these trans---------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Types') IS NOT NULL DROP TABLE #Types
	SELECT a.AdditionalCashbackAwardTypeID
		 , a.TransactionTypeID
		 , a.ItemID
	INTO #Types
	FROM [Relational].[AdditionalCashbackAwardType] a
	WHERE [Description] LIKE '%MyRewards%'
	OR [Title] LIKE '%Credit Card%'

	CREATE CLUSTERED INDEX CIX_TransID_ItemID ON #Types (TransactionTypeID, ItemID)

----------------------------------------------------------------------------------------
------------------------------Find out WHEN the opened their account--------------------
----------------------------------------------------------------------------------------

	DECLARE @Date DATE = DATEADD(day, - @Days, @IntendedSendDate)

	IF OBJECT_ID('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	SELECT l.FanID
		 , l.CompositeID
		 , l.SourceUID
		 , l.ClubID
		 , l.Email
		 , l.AccountName
		 , l.TriggerEmail
		 , iom.IronOfferID
		 , MIN(iom.StartDate) AS StartDate
	INTO #Customers
	FROM #Loyalty l
	INNER JOIN [SLC_Report].[dbo].[IronOfferMember] iom
		ON l.CompositeID = iom.CompositeID
		AND iom.EndDate IS NULL
	WHERE EXISTS (SELECT 1
				  FROM #Accounts a
				  WHERE iom.IronofferID = a.IronOfferID)
	GROUP BY l.FanID
		   , l.CompositeID
		   , l.SourceUID
		   , l.ClubID
		   , l.Email
		   , l.AccountName
		   , l.TriggerEmail
		   , iom.IronOfferID
	HAVING MAX(iom.StartDate) = @Date

	CREATE CLUSTERED INDEX CIX_FanID ON #Customers (FanID)

----------------------------------------------------------------------------------------
------------------------------define date ranges to inspect-----------------------------
----------------------------------------------------------------------------------------


	IF OBJECT_ID('tempdb..#CurrentMonthEnd') IS NOT NULL DROP TABLE #CurrentMonthEnd
	SELECT TOP 500000 *
	INTO #CurrentMonthEnd
	FROM [SLC_Report].[dbo].[Trans] tr
	ORDER BY ID DESC


	DECLARE @CurrentMonthStart DATE
		  , @CurrentMonthEnd DATE
		  , @PreviousMonthStart DATE
		  , @PreviousMonthEnd DATE
	  
	SET @CurrentMonthEnd = (SELECT MAX(cme.[Date])
							FROM #CurrentMonthEnd cme
							WHERE EXISTS (SELECT 1
										  FROM #Types ty
										  WHERE ty.ItemID = cme.ItemID
										  AND ty.TransactionTypeID = cme.TypeID))

	SET @CurrentMonthStart = DATEADD(day, 1, EOMONTH(@CurrentMonthEnd, -1))

	SET @PreviousMonthStart = DATEADD(day, 1, EOMONTH(@CurrentMonthEnd, -2))
	
	SET @PreviousMonthEnd = EOMONTH(@CurrentMonthEnd, -1)

----------------------------------------------------------------------------------------
------------------------------find earnings in last month-----------------------------
----------------------------------------------------------------------------------------


	IF OBJECT_ID('tempdb..#Trans') IS NOT NULL DROP TABLE #Trans
	SELECT *
	INTO #Trans
	FROM [SLC_Report].[dbo].[Trans] tr
	WHERE EXISTS (SELECT 1
				  FROM #Customers osd
				  WHERE tr.FanID = osd.FanID)


	IF OBJECT_ID('tempdb..#Earnings') IS NOT NULL DROP TABLE #Earnings;
	WITH
	TransPreviousMonth AS (SELECT tr.FanID
							    , 'Previous' AS TransMonth
						        , SUM(tr.ClubCash) AS CashbackEarned
						   FROM #Trans tr
						   INNER JOIN #Types t
		  				       ON tr.TypeID = t.TransactionTypeID
		  				       AND tr.ItemID = t.ItemID
						   WHERE tr.Date BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
						   AND EXISTS (SELECT 1
		  				   			   FROM #Customers osd
		  							   WHERE tr.FanID = osd.FanID)
						   GROUP BY tr.FanID),
						   
	TransCurrentMonth AS (SELECT tr.FanID
							   , 'Current' AS TransMonth
						       , SUM(tr.ClubCash) AS CashbackEarned
						  FROM #Trans tr
						  INNER JOIN #Types t
		  				      ON tr.TypeID = t.TransactionTypeID
		  				      AND tr.ItemID = t.ItemID
						  WHERE tr.Date BETWEEN @CurrentMonthStart AND @CurrentMonthEnd
						  AND EXISTS (SELECT 1
		  				   			  FROM #Customers osd
		  							  WHERE tr.FanID = osd.FanID)
						  GROUP BY tr.FanID),

	Trans AS (SELECT FanID
				   , MAX(CashbackEarned) AS CashbackEarned
			  FROM (SELECT FanID
						 , TransMonth
						 , CashbackEarned
					FROM TransPreviousMonth
					UNION ALL
					SELECT FanID
						 , TransMonth
						 , CashbackEarned
					FROM TransPreviousMonth) t
			  GROUP BY FanID)


	SELECT osd.FanID
		 , osd.ClubID
		 , COALESCE(tr.CashbackEarned, 0) AS CashbackEarned
	INTO #Earnings
	FROM #Customers osd
	LEFT JOIN Trans tr
		ON osd.FanID = tr.FanID

	CREATE CLUSTERED INDEX CIX_FanID ON #Earnings (FanID)


----------------------------------------------------------------------------------------
------------------------------Isolate under 3 pound earners-----------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#Under3') IS NOT NULL DROP TABLE #Under3
	SELECT FanID
		 , CashbackEarned
	INTO #Under3
	FROM #Earnings
	WHERE CashbackEarned < 2

	CREATE CLUSTERED INDEX CIX_FanID ON #Under3 (FanID)

----------------------------------------------------------------------------------------
-----------Find entries for accounts that earned (but not the customer)-----------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#AccountEarn') IS NOT NULL DROP TABLE #AccountEarn
	SELECT DISTINCT 
		   u.FanID
		 , u.CashbackEarned
		 , tr.[Date]
		 , tr.VectorMajorID
		 , tr.VectorMinorID
	INTO #AccountEarn
	FROM #Under3 u
	INNER JOIN #Trans tr
		on u.FanID = tr.FanID
	WHERE [Date] BETWEEN @PreviousMonthStart AND @PreviousMonthEnd
	AND tr.TypeID = 24
	AND ItemID IN (66, 79) --*** SB 2017-07-03 Both 3% and 2%

	CREATE CLUSTERED INDEX CIX_VectorIDs ON #AccountEarn (VectorMajorID, VectorMinorID)

----------------------------------------------------------------------------------------
-----------Find value of accounts that earned (but not the customer)-----------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#AlterativeEarnings') IS NOT NULL DROP TABLE #AlterativeEarnings
	SELECT ae.FanID
		 , ae.CashbackEarned
		 , SUM(tr.ClubCash) AS AccountCashbackEarned
	INTO #AlterativeEarnings
	FROM #AccountEarn ae
	INNER JOIN [SLC_Report].[dbo].[Trans] tr
		ON ae.VectorMajorID = tr.VectorMajorID
		AND ae.VectorMinorID = tr.VectorMinorID
	WHERE TypeID = 23
	AND ItemID IN (66, 79) --*** SB 2017-07-03 Both 3% and 2%
	GROUP BY ae.FanID
		   , ae.CashbackEarned

	CREATE CLUSTERED INDEX CIX_FanID ON #AlterativeEarnings (FanID)


----------------------------------------------------------------------------------------
-------------------------------Sum earnings plus account earnings-----------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#TotalEarnings') IS NOT NULL DROP TABLE #TotalEarnings
	SELECT e.FanID
		 , e.CashbackEarned
		 , COALESCE(ae.AccountCashbackEarned, 0) AS Other
		 , e.CashbackEarned + COALESCE(ae.AccountCashbackEarned, 0) AS Earnings
	INTO #TotalEarnings
	FROM #Earnings e
	LEFT JOIN #AlterativeEarnings ae
		ON e.FanID = ae.FanID

	CREATE CLUSTERED INDEX CIX_FanID ON #TotalEarnings (FanID)


----------------------------------------------------------------------------------------
-------------------------------Isolate still not earned £3------------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#StillNotEarned3') IS NOT NULL DROP TABLE #StillNotEarned3
	SELECT l.FanID
		 , l.SourceUID
		 , l.CompositeID
		 , l.ClubID
		 , te.Earnings
	INTO #StillNotEarned3
	FROM #Loyalty l
	INNER JOIN #TotalEarnings te
		ON l.FanID = te.FanID
	WHERE Earnings < 2

	CREATE CLUSTERED INDEX CIX_FanID ON #StillNotEarned3 (FanID)


----------------------------------------------------------------------------------------
--------------------------------Find IssuerCustomerIDs----------------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#IssuerCustomerID') IS NOT NULL DROP TABLE #IssuerCustomerID
	SELECT DISTINCT
		   l.FanID
		 , l.SourceUID
		 , ic.ID AS IssuerCustomerID
		 , l.ClubID
		 , l.CompositeID
	INTO #IssuerCustomerID
	FROM #Loyalty l
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomer] ic
		ON l.SourceUID = ic.SourceUID
		AND CASE
				WHEN l.CLUBID = 132 THEN 2
				ELSE 1
			END = ic.issuerID
	INNER JOIN [SLC_Report].[dbo].[IssuerCustomerAttribute] ica
		ON ic.ID = ica.IssuerCustomerID
		AND ica.EndDate IS NULL

	CREATE CLUSTERED INDEX CIX_IssuerCustomerID ON #IssuerCustomerID (IssuerCustomerID)

----------------------------------------------------------------------------------------
--------------------------------Find non MyReward accounts------------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#BankAccounts') IS NOT NULL DROP TABLE #BankAccounts
	SELECT ic.FanID
		 , ic.SourceUID
		 , ic.IssuerCustomerID
		 , bah.[Type]
		 , bah.BankAccountID
		 , RIGHT(ba.MaskedAccountNumber, 3) AS AccountNumber
		 , ddea.AccountName
	INTO #BankAccounts
	FROM #IssuerCustomerID ic
	INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
		ON ic.IssuerCustomerID = iba.IssuerCustomerID
		AND COALESCE(iba.CustomerStatus, 1) = 1
	INNER JOIN [SLC_Report].[dbo].[BankAccount] ba 
		ON iba.BankAccountID = ba.ID
		AND COALESCE(ba.[Status], 1) = 1
	INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bah 
		ON bah.BankAccountID = iba.BankAccountID
		AND bah.EndDate IS NULL
	LEFT JOIN [Staging].[DirectDebit_EligibleAccounts] ddea
		ON bah.Type = ddea.AccountType
		AND ic.ClubID = ddea.ClubID
	WHERE LEFT(bah.Type, 1) <> 'Q'

	CREATE CLUSTERED INDEX CIX_FanID ON #BankAccounts (FanID)

----------------------------------------------------------------------------------------
--------Remove any who is linked by account to someone who has earned over £3-----------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#EarnedOver3') IS NOT NULL DROP TABLE #EarnedOver3
	SELECT DISTINCT
		   sne.FanID AS FanID1
		 , sne.Earnings AS Earnings1
		 , te.Earnings AS Earnings2
		 , te.FanID AS FanID2
	INTO #EarnedOver3
	FROM #StillNotEarned3 sne
	INNER JOIN #BankAccounts ba1
		ON sne.FanID = ba1.FanID
	INNER JOIN #BankAccounts ba2
		ON ba1.BankAccountID = ba2.BankAccountID
		AND ba1.FanID != ba2.FanID
	INNER JOIN #TotalEarnings te
		ON ba2.FanID = te.FanID
	WHERE te.Earnings >= 2

	CREATE CLUSTERED INDEX CIX_FanID1 ON #EarnedOver3 (FanID1)


----------------------------------------------------------------------------------------
--------------------------------CREATE Final list of Customers--------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('Tempdb..#FinalCustomers') IS NOT NULL DROP TABLE #FinalCustomers
	SELECT te.FanID
		 , te.Earnings
		 , te.Other
		 , te.CashbackEarned
		 , osd.StartDate
	INTO #FinalCustomers
	FROM #TotalEarnings te
	INNER JOIN #StillNotEarned3 sne
		ON te.FanID = sne.FanID
	INNER JOIN #Customers osd
		ON te.FanID = osd.FanID
	WHERE NOT EXISTS (SELECT 1
					  FROM #EarnedOver3 eo
					  WHERE te.FanID = eo.FanID1)

	CREATE CLUSTERED INDEX CIX_FanID ON #FinalCustomers (FanID)

----------------------------------------------------------------------------------------
--------------------------------Add Account Names to list-------------------------------
----------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#FinalCustomersAccounts') IS NOT NULL DROP TABLE #FinalCustomersAccounts;
	WITH
	FinalCustomers AS (SELECT fc.FanID
							, REPLACE(dud.AccountName1,' account','') AS DayXAccountName
					   FROM #FinalCustomers fc
					   INNER JOIN [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
						   ON fc.FanID = dud.FanID
					   WHERE AccountName1 IS NOT NULL
					   UNION ALL
					   SELECT fc.FanID
							, REPLACE(dud.AccountName2,' account','') AS DayXAccountName
					   FROM #FinalCustomers fc
					   INNER JOIN [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
				   			ON fc.FanID = dud.FanID
					   WHERE AccountName2 IS NOT NULL
					   UNION ALL
					   SELECT fc.FanID
				   			 , REPLACE(dud.AccountName3,' account','') AS DayXAccountName
					   FROM #FinalCustomers fc
					   INNER JOIN [SLC_Report].[dbo].[FanSFDDailyUploadData_DirectDebit] dud
				   			ON fc.FanID = dud.FanID
					   WHERE AccountName3 IS NOT NULL)

	SELECT FanID
		 , DayXAccountName
	INTO #FinalCustomersAccounts
	FROM (SELECT FanID
			   , DayXAccountName
			   , ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY CASE
															WHEN DayXAccountName LIKE '%Black%' THEN 1
															WHEN DayXAccountName LIKE '%Plat%' THEN 2
															WHEN DayXAccountName LIKE '%Silve%' THEN 3
															ELSE 4
														 END ASC) AS RowNo
		  FROM FinalCustomers) fc
	WHERE RowNo = 1
	

----------------------------------------------------------------------------------------
--------------------------------------Add to final table--------------------------------
----------------------------------------------------------------------------------------
	IF @Days = 60
		BEGIN
			SELECT cu.TriggerEmail
				 , cu.FanID
				 , cu.Email
				 , DayXAccountName
			FROM #FinalCustomersAccounts fca
			INNER JOIN #Customers cu
				ON fca.FanID = cu.FanID
		END

	IF @Days = 120
		BEGIN
			SELECT DISTINCT
				   cu.TriggerEmail
				 , cu.FanID
				 , cu.Email
				 , fca.DayXAccountName
			FROM #FinalCustomersAccounts fca
			INNER JOIN #Customers cu
				ON fca.FanID = cu.FanID
			INNER JOIN #IssuerCustomerID ic
				ON fca.FanID = ic.FanID
			INNER JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba
				ON ic.IssuerCustomerID = iba.IssuerCustomerID
				AND COALESCE(iba.CustomerStatus, 1) = 1
			INNER JOIN [SLC_Report].[dbo].[BankAccount] ba
				ON iba.BankAccountID = ba.ID
				AND COALESCE(ba.[Status], 1) = 1
			INNER JOIN [SLC_Report].[dbo].[BankAccountTypeHistory] bah
				ON bah.BankAccountID = iba.BankAccountID
				AND bah.EndDate IS NULL
			LEFT JOIN [SLC_Report].[dbo].[IssuerBankAccount] iba2
				ON iba.BankAccountID = iba2.BankAccountID
				AND COALESCE(iba2.CustomerStatus, 1) = 1
				AND iba.IssuerCustomerID != iba2.IssuerCustomerID
			INNER JOIN (SELECT DISTINCT
							   AccountType
							 , REPLACE(AccountName, ' Account', '') AS AccountName
						FROM [Staging].[DirectDebit_EligibleAccounts]
						WHERE LEFT(AccountType, 1) = 'Q' ) ea
				ON bah.Type = ea.AccountType
			WHERE fca.DayXAccountName = ea.AccountName
		END
		
END