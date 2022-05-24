	

CREATE PROCEDURE  [SmartEmail].[TriggerEmail_RetroCalc_20201020]
AS
BEGIN

/*******************************************************************************************************************************************
Product Monitoring
*******************************************************************************************************************************************/

	TRUNCATE TABLE [SmartEmail].[TriggerEmail_ProductMonitoring_Retrospective]
	
	EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 	65				--	@Days INT
																		,	'2020-10-10'	--		,	@SendDate DATE)
																	
	EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 	125				--	@Days INT
																		,	'2020-10-10'	--		,	@SendDate DATE)
	
	EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 	65				--	@Days INT
																		,	'2020-10-13'	--		,	@SendDate DATE)
																	
	EXEC [SmartEmail].[TriggerEmail_ProductMonitoring_RetrospectiveCalc] 	125				--	@Days INT
																		,	'2020-10-13'	--		,	@SendDate DATE)

	EXEC [SmartEmail].[TriggerEmail_FirstEarnMobile_Retrospective] '2020-10-10'	--	@SendDate DATE)

	EXEC [SmartEmail].[TriggerEmail_FirstEarnDirectDebit_Retrospective] '2020-10-10'	--	@SendDate DATE)

	EXEC [SmartEmail].[TriggerEmail_FirstEarnMobile_Retrospective] '2020-10-13'	--	@SendDate DATE)

	EXEC [SmartEmail].[TriggerEmail_FirstEarnDirectDebit_Retrospective] '2020-10-13'	--	@SendDate DATE)

	EXEC [SmartEmail].[TriggerEmail_MobileDormant_Retrospective] '2020-10-13'	--	@SendDate DATE)

/*******************************************************************************************************************************************
Welcome Code
*******************************************************************************************************************************************/

	TRUNCATE TABLE SmartEmail.TriggerEmail_WelcomeEmailCode_Retrospective
	EXEC SmartEmail.TriggerEmail_Welcome_Retrospective '20201010'
	EXEC SmartEmail.TriggerEmail_Welcome_Retrospective '20201013'

		
/*******************************************************************************************************************************************
	1.	Get customers that are not marketable by email 
*******************************************************************************************************************************************/

	IF OBJECT_ID ('tempdb..#NotMarketable') IS NOT NULL DROP TABLE #NotMarketable
	Select FanID
	Into #NotMarketable
	from Relational.customer as c
	Where	c.MarketableByEmail = 0
	
	CREATE CLUSTERED INDEX cix_Marketable_FanID on #NotMarketable (FanID)

/*******************************************************************************************************************************************
	8.	Fetch customers due to receive First Earn emails - Mobile Login & Direct Debit Email
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		8.1.	Fetch customers due to receive First Earn Mobile Login Email
	***************************************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#FirstEarnMobile') IS NOT NULL DROP TABLE #FirstEarnMobile
			SELECT	FanID
				,	AccountName + ' ML' AS AccountName_ML
			INTO #FirstEarnMobile
			FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
			WHERE fe.FirstEarnDate IN ('2020-10-10', '2020-10-13')
			AND fe.FirstEarnType = 'Mobile Login'
			AND NOT EXISTS (SELECT 1
							FROM #NotMarketable ma
							WHERE fe.FanID = ma.FanID)
		
			CREATE CLUSTERED INDEX CIX_FanID on #FirstEarnMobile (FanID)

	/***************************************************************************************************************************************
		8.2.	Fetch customers due to receive First Earn Direct Debit Email
	***************************************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#FirstEarnDirectDebit') IS NOT NULL DROP TABLE #FirstEarnDirectDebit
			SELECT	FanID
				,	AccountName + ' DD'  AS AccountName_DD
			INTO #FirstEarnDirectDebit
			FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
			WHERE fe.FirstEarnDate IN ('2020-10-10', '2020-10-13')
			AND fe.FirstEarnType = 'Direct Debit'
			AND NOT EXISTS (SELECT 1
							FROM #NotMarketable ma
							WHERE fe.FanID = ma.FanID)
		
			CREATE CLUSTERED INDEX CIX_FanID on #FirstEarnDirectDebit (FanID)


	/***************************************************************************************************************************************
		8.2.	Fetch customers due to receive First Earn Direct Debit Email
	***************************************************************************************************************************************/

			IF OBJECT_ID ('tempdb..#FirstEarn') IS NOT NULL DROP TABLE #FirstEarn;
			WITH
			FirstEarn AS (	SELECT	fem.FanID
								,	fem.AccountName_ML AS AccountName
							FROM #FirstEarnMobile fem
							UNION ALL
							SELECT	fed.FanID
								,	fed.AccountName_DD
							FROM #FirstEarnDirectDebit fed)



			SELECT FanID
				 , AccountName = STUFF((SELECT ',' + AccountName
									  FROM FirstEarn t1
									  WHERE t1.FanID = t2.FanID
									  FOR XML PATH ('')), 1, 1, '')
			INTO #FirstEarn
			FROM FirstEarn t2
			GROUP BY FanID;
		
/*******************************************************************************************************************************************
	10.	Fetch customers due to receive Mobile Dormant Email
*******************************************************************************************************************************************/
	
		IF OBJECT_ID ('tempdb..#MobileDormantCustomers') IS NOT NULL DROP TABLE #MobileDormantCustomers
		SELECT	FanID
			,	1 AS CustomField11
		INTO #MobileDormantCustomers
		FROM [SmartEmail].[TriggerEmail_MobileDormantCustomers] mb
		WHERE mb.MobileDormantDate = '2020-10-13'
		AND NOT EXISTS (SELECT 1
						FROM #NotMarketable ma
						WHERE mb.FanID = ma.FanID)

		
/*******************************************************************************************************************************************
	11.	Truncate final table and populate with all fields
*******************************************************************************************************************************************/
	
		UPDATE dd
		SET dd.Day60AccountName = pm.Day60AccountName
		,	dd.Day120AccountName = pm.Day120AccountName
		,	dd.JointAccount = CAST(pm.JointAccount as Bit)
		FROM [SmartEmail].[DailyData] dd
		INNER JOIN [SmartEmail].[TriggerEmail_ProductMonitoring_Retrospective] pm 
			ON dd.FanID = pm.FanID
	
		UPDATE dd
		SET dd.[CustomField10] = fe.AccountName
		FROM [SmartEmail].[DailyData] dd
		INNER JOIN #FirstEarn fe
			ON dd.FanID = fe.FanID
	
		UPDATE dd
		SET dd.[CustomField11] = mdc.CustomField11
		FROM [SmartEmail].[DailyData] dd
		INNER JOIN #MobileDormantCustomers mdc
			ON dd.FanID = mdc.FanID


		UPDATE dd 
		SET dd.WelcomeEmailCode = wec.WelcomeEMailCode 
		FROM SmartEmail.DailyData dd 
		INNER JOIN SmartEmail.TriggerEmail_WelcomeEmailCode_Retrospective wec
			on dd.FaniD = wec.fanid


END
