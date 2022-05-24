
CREATE PROCEDURE [Actito].[TriggerEmails_MopUp_DailyData]
AS
BEGIN

		DECLARE @SendDate_Start DATE = '2021-07-23'
			,	@SendDate_End DATE = '2021-07-24'


		TRUNCATE TABLE [SmartEmail].[TriggerEmail_ProductMonitoring_Retrospective]

		EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 65, @SendDate_Start, @SendDate_End
		EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 125, @SendDate_Start, @SendDate_End

		IF OBJECT_ID('tempdb..#DailyData_TriggerEmailCustomers') IS NOT NULL DROP TABLE #DailyData_TriggerEmailCustomers
		SELECT	FanID
			,	MAX(WelcomeEmailCode) AS WelcomeEmailCode
			,	MAX(FirstEarnDate) AS FirstEarnDate
			,	MAX(FirstEarnType) AS FirstEarnType
			,	MAX(Day60AccountName) AS Day60AccountName
			,	MAX(Day120AccountName) AS Day120AccountName
			,	MAX(DirectDebitEarn_PartnerID) AS DirectDebitEarn_PartnerID
			,	MAX(DirectDebitEarn_TransactionNumber) AS DirectDebitEarn_TransactionNumber
			,	MAX(CONVERT(INT, MobileDormant)) AS MobileDormant
		INTO #DailyData_TriggerEmailCustomers
		FROM Warehouse.SmartEmail.DailyData_TriggerEmailCustomers
		WHERE SendDate BETWEEN @SendDate_Start AND @SendDate_End
		AND TriggerEmail NOT IN ('First Earn Mobile Login', 'First Earn DD')
		GROUP BY FanID

		UPDATE #DailyData_TriggerEmailCustomers
		SET FirstEarnDate = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
		WHERE FirstEarnDate IS NOT NULL

		CREATE CLUSTERED INDEX CIX_FanID ON #DailyData_TriggerEmailCustomers (FanID)

		IF OBJECT_ID('tempdb..#TriggerEmail_FirstEarn_ML') IS NOT NULL DROP TABLE #TriggerEmail_FirstEarn_ML
		SELECT	fe.FanID
			,	fe.AccountName
			,	fe.FirstEarnType
		INTO #TriggerEmail_FirstEarn_ML
		FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
		WHERE fe.FirstEarnType = 'Mobile Login'
		AND fe.FirstEarnDate BETWEEN CONVERT(DATE, DATEADD(DAY, -1, @SendDate_Start)) AND CONVERT(DATE, DATEADD(DAY, -1, @SendDate_End))
		AND EXISTS (SELECT 1
					FROM [Warehouse].[SmartEmail].[DailyData] dd
					WHERE fe.FanID = dd.FanID
					AND dd.Marketable = 1
					AND dd.LoyaltyAccount = 1)

		CREATE CLUSTERED INDEX CIX_FanID ON #TriggerEmail_FirstEarn_ML (FanID)

		IF OBJECT_ID('tempdb..#TriggerEmail_FirstEarn_DD') IS NOT NULL DROP TABLE #TriggerEmail_FirstEarn_DD
		SELECT	fe.FanID
			,	fe.AccountName
			,	fe.FirstEarnType
		INTO #TriggerEmail_FirstEarn_DD
		FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
		WHERE fe.FirstEarnType = 'Direct Debit'
		AND fe.FirstEarnDate BETWEEN CONVERT(DATE, DATEADD(DAY, -1, @SendDate_Start)) AND CONVERT(DATE, DATEADD(DAY, -1, @SendDate_End))
		AND EXISTS (SELECT 1
					FROM [Warehouse].[SmartEmail].[DailyData] dd
					WHERE fe.FanID = dd.FanID
					AND dd.Marketable = 1
					AND dd.LoyaltyAccount = 1)

		CREATE CLUSTERED INDEX CIX_FanID ON #TriggerEmail_FirstEarn_DD (FanID)

		IF OBJECT_ID('tempdb..#DailyData') IS NOT NULL DROP TABLE #DailyData
		SELECT	FanID = dd.FanID	-- Daily Data

			,	Welcome_Code = COALESCE(tec.WelcomeEmailCode, dd.WelcomeEmailCode, '')

			,	Birthday_Flag = ''
			,	Birthday_Code = COALESCE(CAST(dd.CaffeNeroBirthdayCode AS NVARCHAR(255)), '')
			,	Birthday_CodeExpiryDate = ''

			,	FirstEarn_Date = COALESCE(tec.FirstEarnDate, dd.[FirstEarnDate])
			,	FirstEarn_TransactionAmount = CAST('' AS NVARCHAR(24))
			,	FirstEarn_CashbackAmount = ''
			,	FirstEarn_Type = CAST(COALESCE(tec.[FirstEarnType], dd.[FirstEarnType]) AS NVARCHAR(255))
			,	FirstEarn_RetailerName = CAST('' AS NVARCHAR(255))

			,	Reached5GBP_Date = dd.[Reached5GBP]

			,	RedeemReminder_Day = ''
			,	RedeemReminder_Amount = CAST('' AS NVARCHAR(24))

			,	EarnConfirmation_Date = ''

			,	Homemover_Flag = dd.[Homemover]

			,	ProductMon_Day60AccountName = COALESCE(dd.[Day60AccountName], pm.[Day60AccountName], '')
			,	ProductMon_Day120AccountName = COALESCE(dd.[Day120AccountName], pm.[Day120AccountName], '')

			,	FulfillmentTypeID = CASE when dd.[FulfillmentTypeID] is NULL then 0 else dd.[FulfillmentTypeID] END

			,	Reward30_FirstEarnDD = COALESCE(dir.AccountName + ' DD', '')
			,	Reward30_FirstEarnMobile = COALESCE(ml.AccountName + ' ML', '')
			,	Reward30_MobileDormancy =	CASE
												WHEN tec.MobileDormant IS NOT NULL THEN 1
												ELSE 0
											END
		INTO #DailyData
		FROM [Warehouse].[SmartEmail].[DailyData] dd
		LEFT JOIN [SmartEmail].[TriggerEmail_ProductMonitoring_Retrospective] pm
			ON dd.FanID = pm.FanID
		LEFT JOIN #DailyData_TriggerEmailCustomers tec
			ON dd.FanID = tec.FanID
		LEFT JOIN #TriggerEmail_FirstEarn_ML ml
			ON dd.FanID = ml.FanID
		LEFT JOIN #TriggerEmail_FirstEarn_DD dir
			ON dd.FanID = dir.FanID

		SELECT *
		FROM #DailyData
		WHERE Welcome_Code != ''
		OR FirstEarn_Type != ''
		OR ProductMon_Day60AccountName != ''
		OR ProductMon_Day120AccountName != ''
		OR Reward30_FirstEarnDD != ''
		OR Reward30_FirstEarnMobile != ''
		OR Reward30_MobileDormancy = 1

	END




	

	/*
	
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'Mobile Dormant' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE Reward30_MobileDormancy = 1
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		UNION ALL
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), CASE
																																							WHEN  Welcome_Code LIKE '%W7%' AND Welcome_Code LIKE '%RB%' THEN 'Credit Card - CC Only - Reward Black'
																																							WHEN  Welcome_Code LIKE '%W7%' THEN 'Credit Card - CC Only'
																																							WHEN  Welcome_Code LIKE '%W8%' AND Welcome_Code LIKE '%RB%' THEN 'Credit Card - Adding CC - Reward Black'
																																							WHEN  Welcome_Code LIKE '%W8%' THEN 'Credit Card - Adding CC'
																																					   END AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE Welcome_Code IN ('W7-RB', 'W7', 'W8-RB', 'W8')
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END, CASE
																																							WHEN  Welcome_Code LIKE '%W7%' AND Welcome_Code LIKE '%RB%' THEN 'Credit Card - CC Only - Reward Black'
																																							WHEN  Welcome_Code LIKE '%W7%' THEN 'Credit Card - CC Only'
																																							WHEN  Welcome_Code LIKE '%W8%' AND Welcome_Code LIKE '%RB%' THEN 'Credit Card - Adding CC - Reward Black'
																																							WHEN  Welcome_Code LIKE '%W8%' THEN 'Credit Card - Adding CC'
																																					   END
		UNION ALL		
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'First Earn POS' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE FirstEarn_Type != ''
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		UNION ALL		
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'Product Monitoring - 60 Days' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE ProductMon_Day60AccountName != ''
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		UNION ALL		
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'Product Monitoring - 120 Days' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE ProductMon_Day120AccountName != ''
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		UNION ALL		
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'First Earn DD' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE Reward30_FirstEarnDD != ''
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		UNION ALL		
		SELECT CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END AS Brand, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END AS Loyalty, COUNT(*), 'First Earn Mobile Login' AS Email
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE Reward30_FirstEarnMobile != ''
		GROUP BY CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END
		ORDER BY 4, CASE WHEN ClubID = 132 THEN 'NW' ELSE 'RBS' END, CASE WHEN IsLoyalty = 0 THEN 'Core' ELSE 'Premier' END

		



		SELECT dd.FirstEarn_Date, COUNT(*)
		FROM #DailyData dd
		INNER JOIN SmartEmail.DailyData d
			ON dd.FanID = d.FanID
		WHERE FirstEarn_Type != ''
		GROUP BY FirstEarn_Date
		ORDER BY FirstEarn_Date


		*/