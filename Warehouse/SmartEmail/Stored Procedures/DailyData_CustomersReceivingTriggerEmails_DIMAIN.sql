
CREATE PROCEDURE [SmartEmail].[DailyData_CustomersReceivingTriggerEmails_DIMAIN]

AS
BEGIN

	DECLARE @SendDate DATE = GETDATE()
	DECLARE @PreviousDay DATE = DATEADD(day, -1, @SendDate)
			
	/***********************************************************************************************************************
							Fetch all customers matching any of the criteria fOR a trigger email
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TriggerEmailsTemp') IS NOT NULL DROP TABLE #TriggerEmailsTemp
		SELECT	dd.FanID
			 ,	Email
			 ,	IsLoyalty
			 ,	ClubID
			 ,	CASE
					WHEN ClubID = 132 THEN 'NW'
					WHEN ClubID = 138 THEN 'RBS'
					ELSE NULL
				END AS Brand
			 ,	CASE
					WHEN IsLoyalty = 0 THEN 'Core'
					WHEN IsLoyalty = 1 THEN 'Prime'
					ELSE NULL
				END AS Loyalty
			 ,	WelcomeEmailCode
			 ,	dd.FirstEarnDate
			 ,	dd.FirstEarnType
			 ,	Day60AccountName
			 ,	Day120AccountName
			 ,	Homemover
			 ,	LoyaltyAccount
			 ,	mfdd.RetailerPaymentNumber
			 ,	feml.AccountName AS FirstEarn_MobileLogin
			 ,	fedd.AccountName AS FirstEarn_DirectDebit
			 ,	md.MobileDormantDate
		INTO #TriggerEmailsTemp
		FROM [Warehouse].[SmartEmail].[DailyData] dd
		LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] feml
			ON dd.FanID = feml.FanID
			AND dd.Marketable = 1
			AND feml.FirstEarnType = 'Mobile Login'
			AND feml.FirstEarnDate = @PreviousDay
		LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] fedd
			ON dd.FanID = fedd.FanID
			AND dd.Marketable = 1
			AND fedd.FirstEarnType = 'Direct Debit'
			AND fedd.FirstEarnDate = @PreviousDay
		LEFT JOIN [SmartEmail].[TriggerEmail_MobileDormantCustomers] md
			ON dd.FanID = md.FanID
			AND dd.Marketable = 1
			AND md.MobileDormantDate = @SendDate
		LEFT JOIN [Actito].[MFDDData] mfdd
			ON dd.FanID = mfdd.FanID			
		WHERE WelcomeEmailCode LIKE '%W7%'
		OR WelcomeEmailCode LIKE'%W8%'
		OR Day60AccountName IS NOT NULL
		OR Day120AccountName IS NOT NULL
		OR feml.AccountName IS NOT NULL
		OR fedd.AccountName IS NOT NULL
		OR md.MobileDormantDate IS NOT NULL
		OR mfdd.RetailerPaymentNumber IS NOT NULL
		OR Homemover = 1
		OR (dd.FirstEarnDate = @PreviousDay AND (dd.FirstEarnType = 'credit card payment' OR dd.FirstEarnType LIKE '%debit card%'))
		OR (dd.FirstEarnDate = @PreviousDay AND dd.FirstEarnType IN ('direct debit frontbook'))

			
	/***********************************************************************************************************************
							Split out MFDD trigger information by Partner & Transaction Number
	***********************************************************************************************************************/
	
		IF OBJECT_ID('tempdb..#MFDD') IS NOT NULL DROP TABLE #MFDD
		SELECT	FanID
			,	Email
			,	CASE
					WHEN ClubID = 132 THEN 'NW'
					WHEN ClubID = 138 THEN 'RBS'
					ELSE NULL
				END AS Brand
			,	CASE
					WHEN IsLoyalty = 0 THEN 'Core'
					WHEN IsLoyalty = 1 THEN 'Prime'
					ELSE NULL
				END AS Loyalty
			,	RetailerPaymentNumber
		INTO #MFDD
		FROM #TriggerEmailsTemp dd
		WHERE RetailerPaymentNumber IS NOT NULL

		IF OBJECT_ID('tempdb..#MFDD_AllEmails') IS NOT NULL DROP TABLE #MFDD_AllEmails
		SELECT	FanID
			,	ss1.Item
			, 	MIN(ss2.Item) AS TransactionNumber
			,	MAX(ss2.Item) AS PartnerID
			,	0 AS OldSkyLogic
		INTO #MFDD_AllEmails
		FROM #MFDD mf
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (RetailerPaymentNumber, ';') ss1
		CROSS APPLY [dbo].[il_SplitDelimitedStringArray] (ss1.Item, '-') ss2
		GROUP BY FanID
			   , ss1.Item


	/***********************************************************************************************************************
			  Split fetched customers by their relevant trigger email AND INSERT them INTO monthly holding table
	***********************************************************************************************************************/

		INSERT INTO SmartEmail.DailyData_TriggerEmailCustomers (SendDate
															  , TriggerEmail
															  , Brand
															  , Loyalty
															  , FanID
															  , InCountsTable
															  , WelcomeEmailCode
															  , Homemover
															  , FirstEarnDate
															  , FirstEarnType
															  , Day60AccountName
															  , Day120AccountName
															  , LoyaltyAccount
															  , DirectDebitEarn_PartnerID
															  , DirectDebitEarn_TransactionNumber
															  , MobileDormant)

		SELECT @SendDate AS SendDate
			 , [all].TriggerEmail
			 , [all].Brand
			 , [all].Loyalty
			 , [all].FanID
			 , 0 AS InCountsTable
			 , [all].WelcomeEmailCode
			 , [all].Homemover
			 , [all].FirstEarnDate
			 , [all].FirstEarnType
			 , [all].Day60AccountName
			 , [all].Day120AccountName
			 , [all].LoyaltyAccount
			 , [all].DirectDebitEarn_PartnerID
			 , [all].DirectDebitEarn_TransactionNumber
			 , [all].MobileDormant
		FROM (	
				--	Credit Card - Adding CC Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , CASE
							WHEN WelcomeEmailCode LIKE '%RB%' THEN 'Credit Card - Adding CC - Reward Black'
							ELSE 'Credit Card - Adding CC'
					   END AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE WelcomeEmailCode LIKE '%W7%'

				UNION ALL
		
				--	Credit Card - CC Only Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , CASE
							WHEN WelcomeEmailCode LIKE '%RB%' THEN 'Credit Card - CC Only - Reward Black'
							ELSE 'Credit Card - CC Only'
					   END AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE WelcomeEmailCode LIKE '%W8%'

				UNION ALL
		
				--	First Earn POS Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , FirstEarnDate
					 , FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'First Earn POS' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE FirstEarnDate = @PreviousDay
				AND (	FirstEarnType = 'credit card payment'
					 OR FirstEarnType LIKE '%debit card%')

				UNION ALL
		
				--	First Earn DD Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , CASE WHEN FirstEarn_DirectDebit IS NOT NULL THEN 'First Earn DD' END AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'First Earn DD' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE FirstEarn_DirectDebit IS NOT NULL

				UNION ALL
		
				--	First Earn Mobile Login Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , CASE WHEN FirstEarn_MobileLogin IS NOT NULL THEN 'Mobile Login' END AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'First Earn Mobile Login' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE FirstEarn_MobileLogin IS NOT NULL

				UNION ALL
		
				--	Product Monitoring 60 Day Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'Product Monitoring 60 Day' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE Day60AccountName IS NOT NULL

				UNION ALL
		
				--	Product Monitoring 120 Day Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'Product Monitoring 120 Day' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE Day120AccountName IS NOT NULL

				UNION ALL
		
				--	Homemover Customers
				SELECT FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS DirectDebitEarn_PartnerID
					 , NULL AS DirectDebitEarn_TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'Homemovers' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE Homemover = 1
				AND LoyaltyAccount = 1

				UNION ALL
		
				--	MFDD First Payment Customers
				SELECT DISTINCT
					   dd.FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , PartnerID
					 , TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'MFDD First Payment - ' + pa.Name + CASE
															WHEN pa.ID = 4729 AND OldSkyLogic = 1 THEN ' £50 or £75'
															WHEN pa.ID = 4729 AND OldSkyLogic = 0 THEN ' £50 or £70'
															ELSE ''
														END AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				INNER JOIN #MFDD_AllEmails mf
					ON dd.FanID = mf.FanID
				INNER JOIN SLC_REPL..Partner pa
					ON mf.PartnerID = pa.ID
				WHERE TransactionNumber = 1
				
				UNION ALL
		
				--	MFDD First Earn Customers
				SELECT DISTINCT
					   dd.FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , PartnerID
					 , TransactionNumber
					 , NULL AS MobileDormant
					 , LoyaltyAccount
					 , 'MFDD First Earn - ' + pa.Name + CASE
															WHEN pa.ID = 4729 AND OldSkyLogic = 1 THEN ' £50 or £75'
															WHEN pa.ID = 4729 AND OldSkyLogic = 0 THEN ' £50 or £70'
															ELSE ''
														END AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				INNER JOIN #MFDD_AllEmails mf
					ON dd.FanID = mf.FanID
				INNER JOIN SLC_REPL..Partner pa
					ON mf.PartnerID = pa.ID
				WHERE TransactionNumber = 2
				
				UNION ALL
		
				--	Mobile Dormant Customers
				SELECT DISTINCT
					   dd.FanID
					 , Email
					 , Brand
					 , Loyalty
					 , NULL AS WelcomeEmailCode
					 , NULL AS Homemover
					 , NULL AS FirstEarnDate
					 , NULL AS FirstEarnType
					 , NULL AS Day60AccountName
					 , NULL AS Day120AccountName
					 , NULL AS PartnerID
					 , NULL AS TransactionNumber
					 , 1 AS MobileDormant
					 , LoyaltyAccount
					 , 'Mobile Dormant' AS TriggerEmail
				FROM #TriggerEmailsTemp dd
				WHERE MobileDormantDate IS NOT NULL) [all]
		WHERE NOT EXISTS (SELECT 1
						  FROM SmartEmail.DailyData_TriggerEmailCustomers tec
						  WHERE [all].FanID = tec.FanID
						  AND [all].TriggerEmail = tec.TriggerEmail
						  AND @SendDate = tec.SendDate)

	/***********************************************************************************************************************
			   Create temp table holding all possible entries fOR trigger email & brAND / loyalty combinations
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TriggerEmails') IS NOT NULL DROP TABLE #TriggerEmails
		Create table #TriggerEmails (TriggerEmail varchar(50))

		INSERT INTO #TriggerEmails(TriggerEmail) VALUES
		('Credit Card - Adding CC'),
		('Credit Card - CC Only'),
		('Credit Card - Adding CC - Reward Black'),
		('Credit Card - CC Only - Reward Black'),
		('First Earn DD'),
		('First Earn POS'),
		('First Earn Mobile Login'),
		('Mobile Dormant'),
		('Homemovers'),
		('Product Monitoring 120 Day'),
		('Product Monitoring 60 Day'),
		('MFDD First Payment - Sky £50 or £75'),
		('MFDD First Earn - Sky £50 or £75'),
		('MFDD First Payment - Sky £50 or £70'),
		('MFDD First Earn - Sky £50 or £70'),
		('MFDD First Payment - Sky Mobile'),
		('MFDD First Earn - Sky Mobile'),
		('MFDD First Payment - Eon'),
		('MFDD First Earn - Eon')

		IF OBJECT_ID('tempdb..#TriggerEmailsAll') IS NOT NULL DROP TABLE #TriggerEmailsAll
		SELECT *
		INTO #TriggerEmailsAll
		FROM #TriggerEmails te
		Cross join (SELECT 'NW' AS Brand
					Union
					SELECT 'RBS' AS Brand) b
		Cross join (SELECT 'Core' AS Loyalty
					Union
					SELECT 'Prime' AS Loyalty) l
		Order by TriggerEmail
				,Brand
				,Loyalty

	/***********************************************************************************************************************
		 INSERTs all possible combinations to a table aggregated by distinct FanID if no entry fOR current date exists
	***********************************************************************************************************************/
	
		INSERT INTO SmartEmail.DailyData_TriggerEmailCounts
		SELECT @SendDate AS SendDate
			 , te.TriggerEmail
			 , te.Brand
			 , te.Loyalty
			 , 0 AS CustomersEmailed
		FROM #TriggerEmailsAll te
		WHERE NOT EXISTS (	SELECT 1
							FROM SmartEmail.DailyData_TriggerEmailCounts tec
							WHERE tec.SendDate = @SendDate
							AND te.TriggerEmail = tec.TriggerEmail)
	
	/***********************************************************************************************************************
										Aggregate customers receiving daily trigger emails
	***********************************************************************************************************************/

		IF OBJECT_ID('tempdb..#TriggerEmailCounts') IS NOT NULL DROP TABLE #TriggerEmailCounts
		SELECT SendDate
			 , TriggerEmail
			 , Brand
			 , Loyalty
			 , Count(Distinct FanID) AS CustomersEmailed
		INTO #TriggerEmailCounts
		FROM SmartEmail.DailyData_TriggerEmailCustomers
		WHERE SendDate = @SendDate
		And	  InCountsTable = 0
		Group by SendDate
				,TriggerEmail
				,Brand
				,Loyalty

		
	/***********************************************************************************************************************
		Update aggreation adding new customers, show customers AS added to aggregation AND delete entries + 12 months old
	***********************************************************************************************************************/

		--	Update aggreation adding new customers
			Update te_counts
			Set te_counts.CustomersEmailed = te_counts.CustomersEmailed + te_counts_temp.CustomersEmailed
			FROM SmartEmail.DailyData_TriggerEmailCounts te_counts
			Inner join #TriggerEmailCounts te_counts_temp
				on  te_counts.TriggerEmail = te_counts_temp.TriggerEmail
				and	te_counts.BrAND = te_counts_temp.Brand
				and	te_counts.Loyalty = te_counts_temp.Loyalty
				and	te_counts.SendDate = te_counts_temp.SendDate

		--	Show customers AS added to aggregation
			Update te_cust
			Set InCountsTable = 1
			FROM SmartEmail.DailyData_TriggerEmailCustomers te_cust
			WHERE SendDate = @SendDate
			AND InCountsTable = 0

		--	Delete entries + 12 months old
			Delete FROM SmartEmail.DailyData_TriggerEmailCustomers
			WHERE SendDate < DATEADD(month,-12,@SendDate)

End