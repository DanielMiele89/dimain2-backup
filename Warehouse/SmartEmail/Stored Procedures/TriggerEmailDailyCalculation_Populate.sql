/********************************************************************************************
	Name: SmartEmail.TriggerEmailDailyCalculation_Populate
	Desc: Populates the DailyData table
	Auth: Zoe Taylor

	Change History
			ZT 17/05/2018 - Stored procedure created
			ZT 15/01/2021 - Changes for Actito implementation to populate deltas
				
	
*********************************************************************************************/

CREATE PROCEDURE [SmartEmail].[TriggerEmailDailyCalculation_Populate]

AS
BEGIN

SET XACT_ABORT ON

		DECLARE @Today DATE = GETDATE()
		
/*******************************************************************************************************************************************
	1.	Get customers that are not marketable by email 
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#NotMarketable') IS NOT NULL DROP TABLE #NotMarketable
		SELECT FanID
		INTO #NotMarketable
		FROM Relational.customer as c
		WHERE c.MarketableByEmail = 0
		
		CREATE CLUSTERED INDEX cix_Marketable_FanID on #NotMarketable (FanID)

		IF OBJECT_ID ('tempdb..#Marketable') IS NOT NULL DROP TABLE #Marketable
		SELECT	FanID
			,	MarketableByEmail
		INTO #Marketable
		FROM Relational.customer as c
		WHERE c.MarketableByEmail = 1
		
		CREATE CLUSTERED INDEX cix_Marketable_FanID on #Marketable (FanID)

		
/*******************************************************************************************************************************************
	2.	Find customers with a birthday today for redemption code
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Birthdays') IS NOT NULL DROP TABLE #Birthdays
		SELECT FanID
		INTO #Birthdays
		FROM Relational.Customer as c
		WHERE Day(GETDATE()) = DAY(DOB) 
			AND	Month(GETDATE()) = Month(DOB) 
			AND	CurrentlyActive = 1
		
		CREATE CLUSTERED INDEX cix_Birthday_FanID on #Birthdays (FanID)

		
/*******************************************************************************************************************************************
	3.	Find batch of codes
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Batches') IS NOT NULL DROP TABLE #Batches
		SELECT TOP 2 BatchID
		INTO #Batches
		FROM Relational.RedemptionCodeBatch AS a
		WHERE CodeTypeID = 1
		ORDER BY BatchID DESC

		
/*******************************************************************************************************************************************
	4.	Get list of hardbounced customers
*******************************************************************************************************************************************/

		--IF OBJECT_ID ('tempdb..#Hardbounced') IS NOT NULL DROP TABLE #Hardbounced
		--SELECT Email = CAST(Email AS NVARCHAR(100)) -- CJM 20180622 avoids implicit conversion
		--	, FanID
		--INTO #Hardbounced
		--FROM Relational.Customer as c
		--WHERE Hardbounced = 1
		--AND c.FanID NOT IN (23561109)	--	Forcing one customer in for resend 2021-11-02, to be removed after this date

		--CREATE CLUSTERED INDEX cix_Hardbounced_FanID on #Hardbounced (FanID,Email)

		
/*******************************************************************************************************************************************
	5.	Find codes for people with birthdays
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes
		SELECT Max(rc.Code) as Code
			, rc.FanID
		INTO #Codes
		FROM Relational.RedemptionCode as rc
		INNER JOIN #Batches as b
			ON	rc.BatchID = b.BatchID
		INNER JOIN #Birthdays as a
			ON  rc.FanID = a.FanID
		GROUP BY rc.FanID

		CREATE CLUSTERED INDEX cix_Codes_FanID on #Codes (FanID)

		
/*******************************************************************************************************************************************
	6.	Get customers with valid email addresses
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Fan') IS NOT NULL DROP TABLE #Fan
		SELECT	FanID = fa.ID
			,	fa.Email
			,	fa.FirstName
			,	fa.LastName
			,	fa.ClubCashAvailable
			,	fa.ClubCashPending
			,	DOB = CONVERT(DATE, fa.DOB)
			,	fa.Sex
			,	fa.Title
			,	fa.AgreedTCSDate
			,	fa.ClubID
			,	fa.Postcode
		INTO #Fan
		FROM [SLC_Report].[dbo].[Fan] fa
		WHERE fa.ClubID IN (132, 138)
		AND fa.Status = 1
		AND fa.AgreedTCSDate IS NOT NULL
		AND fa.AgreedTCs = 1
		AND fa.DeceasedDate IS NULL		

		CREATE CLUSTERED INDEX CIX_FanID ON #Fan (FanID)
		CREATE NONCLUSTERED INDEX IX_OfflineEmail ON #Fan (Email, FanID)

		UPDATE fa
		SET Email = 'NoEmail@RewardInsight.com'
		FROM #Fan fa
		WHERE REPLACE(fa.Email, ' ', '') = ''
						
		UPDATE fa
		SET fa.Email = 'InvalidEmail@RewardInsight.com'
		FROM #Fan fa
		INNER JOIN [Relational].[Customer] cu
			ON fa.FanID = cu.FanID
			AND fa.Email = cu.Email
		WHERE cu.EmailStructureValid = 0
		AND fa.Email NOT IN ('InvalidEmail@RewardInsight.com', 'NoEmail@RewardInsight.com')

		;WITH
		NewEmailAddresses AS (	SELECT	FanID
									,	Email
								FROM #Fan fa
								WHERE NOT EXISTS (	SELECT 1
													FROM [Relational].[Customer] cu
													WHERE fa.FanID = cu.FanID
													AND fa.Email = cu.Email)
								AND fa.Email NOT IN ('InvalidEmail@RewardInsight.com', 'NoEmail@RewardInsight.com'))

		UPDATE nea
		SET nea.Email =	CASE
							WHEN esv.EmailStructureValid = 0 THEN 'InvalidEmail@RewardInsight.com'
							ELSE nea.Email
						END
		FROM NewEmailAddresses nea
		CROSS APPLY [WH_AllPublishers].[dbo].[iTVF_IsEmailStructureValid] (nea.Email) esv
		
/*******************************************************************************************************************************************
	7.	Get fetch todays MFDD email customers
*******************************************************************************************************************************************/
	
		IF OBJECT_ID ('tempdb..#MFDD_TriggerEmail') IS NOT NULL DROP TABLE #MFDD_TriggerEmail
		SELECT PartnerID
			 , IronOfferID
			 , MAX(TransactionNumber) AS TransactionNumber
			 , FanID
			 , ROW_NUMBER () OVER (PARTITION BY FanID ORDER BY IronOfferID DESC) AS FanRowNum
		INTO #MFDD_TriggerEmail
		FROM [SmartEmail].[SFD_DailyLoad_MFDD_TriggerEmail] mfdd
		WHERE EmailDate = @Today
		AND NOT EXISTS (SELECT 1
						FROM #NotMarketable ma
						WHERE mfdd.FanID = ma.FanID)
		GROUP BY PartnerID
			   , IronOfferID
			   , FanID

		CREATE CLUSTERED INDEX cix_FanID on #MFDD_TriggerEmail (FanID)

		IF OBJECT_ID ('tempdb..#MFDD_Email') IS NOT NULL DROP TABLE #MFDD_Email;
		WITH
		MFDD_Email AS (	SELECT *
						FROM #MFDD_TriggerEmail
						WHERE IronOfferID != 16535)

		SELECT FanID
			 , MFDDEmail = STUFF((SELECT ',' + CONVERT(VARCHAR(5), PartnerID) + '-' + CONVERT(VARCHAR(5), TransactionNumber)
								  FROM MFDD_Email t1
								  WHERE t1.FanID = t2.FanID
								  FOR XML PATH ('')), 1, 1, '')
		INTO #MFDD_Email
		FROM MFDD_Email t2
		GROUP BY FanID;

		DELETE
		FROM #MFDD_TriggerEmail
		WHERE IronOfferID != 16535


/*******************************************************************************************************************************************
	8.	Fetch customers due to receive First Earn emails - Mobile Login & Direct Debit Email
*******************************************************************************************************************************************/

	/***************************************************************************************************************************************
		8.1.	Fetch customers due to receive First Earn Mobile Login Email
	***************************************************************************************************************************************/
		
			DECLARE @Yesterday DATE = DATEADD(DAY, -1, GETDATE())

			IF OBJECT_ID ('tempdb..#FirstEarnMobile') IS NOT NULL DROP TABLE #FirstEarnMobile
			SELECT	FanID
				,	AccountName + ' ML' AS AccountName_ML
			INTO #FirstEarnMobile
			FROM [SmartEmail].[TriggerEmail_FirstEarn] fe
			WHERE fe.FirstEarnDate = @Yesterday
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
			WHERE fe.FirstEarnDate = @Yesterday
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
			,	1 AS MobileDormant
		INTO #MobileDormantCustomers
		FROM [SmartEmail].[TriggerEmail_MobileDormantCustomers] mb
		WHERE mb.MobileDormantDate = @Today
		AND NOT EXISTS (SELECT 1
						FROM #NotMarketable ma
						WHERE mb.FanID = ma.FanID)

		
/*******************************************************************************************************************************************
	11.	Truncate final table and populate with all fields
*******************************************************************************************************************************************/
	
	BEGIN TRAN --Delta Processing
	

		DECLARE @Today_DailyDataLog DATE = GETDATE()
			,	@DailyDataLogEntriesForToday INT
			,	@Weekday VARCHAR(15) = (SELECT DATENAME (dw , GETDATE()))

		SELECT @DailyDataLogEntriesForToday = COUNT(*)
		FROM [SmartEmail].[SmartEmailDailyDataLog]
		WHERE CONVERT(DATE, CompletionDate) = @Today_DailyDataLog
			   		 

	/******************************************************************		
			Truncate yesterdays table and copy data
	******************************************************************/

		IF @DailyDataLogEntriesForToday = 0 AND @Weekday NOT IN ('Sunday', 'Monday') AND @Today_DailyDataLog != '2021-10-01'
			BEGIN
				
				TRUNCATE TABLE [SmartEmail].[DailyData_PreviousDay]

				INSERT INTO [SmartEmail].[DailyData_PreviousDay]
				SELECT * 
				FROM [SmartEmail].[DailyData]

			END
	
			
	/******************************************************************		
			Truncate final table and populate with all fields 
	******************************************************************/
	
		TRUNCATE TABLE [SmartEmail].[DailyData]
		INSERT INTO [SmartEmail].[DailyData] (	[Email]
											,	[FanID]
											,	[ClubID]
											,	[ClubName]
											,	[FirstName]
											,	[LastName]
											,	[DOB]
											,	[Sex]
											,	[FromAddress]
											,	[FromName]
											,	[ClubCashAvailable]
											,	[ClubCashPending]
											,	[PartialPostCode]
											,	[Title]
											,	[AgreedTcsDate]
											,	[WelcomeEmailCode]
											,	[IsDebit]
											,	[IsCredit]
											,	[Nominee]
											,	[RBSNomineeChange]
											,	[LoyaltyAccount]
											,	[IsLoyalty]
											,	[FirstEarnDate]
											,	[FirstEarnType]
											,	[Reached5GBP]
											,	[Homemover]
											,	[Day60AccountName]
											,	[Day120AccountName]
											,	[JointAccount]
											,	[FulfillmentTypeID]
											,	[CaffeNeroBirthdayCode]
											,	[ExpiryDate]
											,	[LvTotalEarning]
											,	[LvCurrentMonthEarning]
											,	[LvMonth1Earning]
											,	[LvMonth2Earning]
											,	[LvMonth3Earning]
											,	[LvMonth4Earning]
											,	[LvMonth5Earning]
											,	[LvMonth6Earning]
											,	[LvMonth7Earning]
											,	[LvMonth8Earning]
											,	[LvMonth9Earning]
											,	[LvMonth10Earning]
											,	[LvMonth11Earning]
											,	[LvCPOSEarning]
											,	[LvDPOSEarning]
											,	[LvDDEarning]
											,	[LvOtherEarning]
											,	[LvCurrentAnniversaryEarning]
											,	[LvPreviousAnniversaryEarning]
											,	[LvEAYBEarning]
											,	[Marketable]
											--,	[CustomField7]	-- SKY Trigger Email
											--,	[CustomField8]	-- SKY Trigger Email
											--,	[CustomField9]	-- MFDD Trigger Email
											--,	[CustomField10]	-- First Earn Mobile & Direct Debit Trigger Email
											--,	[CustomField11]	-- Mobile Dormant Trigger Email
											)
		SELECT f.Email
			 , f.FanID
			 , f.ClubID
			 , '' as ClubName
			 , f.FirstName AS [FirstName]
			 , f.LastName AS [Lastname]
			 , f.DOB as dob
			 , f.Sex
			 , '' as FromAddress
			 , '' as FromName
			 , f.ClubCashAvailable AS ClubCashAvailable
			 , f.ClubCashPending-f.ClubCashAvailable AS ClubCashPending
			 , RIGHT(RTRIM(f.POSTCODE),3) AS [partial postcode]
			 , f.Title AS [Title]
			 , f.AgreedTcsDate
			 , p2df.WelcomeEmailCode
			  --	f.ActivationChannel,
			 , [IsDebit] = COALESCE(p2df.[IsDebit], 0)
			 , [IsCredit] = COALESCE(p2df.[IsCredit], 0)
			 , Coalesce(CAST(dd.[Nominee] as Bit),0) as Nominee
			 , Coalesce(CAST(dd.[RBSNomineeChange] as Bit),0) as RBSNomineeChange
			 , [LoyaltyAccount] = COALESCE(CAST(p2df.LoyaltyAccount as Bit), 0)
			 , [IsLoyalty] = COALESCE(CAST(p2df.IsLoyalty as Bit), 0)
			 , p2df.FirstEarnDate
			 , p2df.FirstEarnType
			 , p2df.Reached5GBP
			 , [Homemover] = COALESCE(CAST(p2df.Homemover as Bit), 0)
			 , pm.Day60AccountName
			 , pm.Day120AccountName
			 , CAST(pm.JointAccount as Bit) as JointAccount
			 , Case
			   		When r.Redeemed = 1 then 1
			   		Else NULL
			   End as FulfillmentTypeID
			 , codes.Code as CaffeNeroBirthdayCode
			 , Cast(Case
						When codes.Code IS not null then Dateadd(week,2,GETDATE())
						Else null
					End as Date) as ExpiryDate
			 , isnull(ltv.DDEarning,0)+isnull(ltv.DPOSEarning,0)+isnull(ltv.CPOSEarning,0)+isnull(ltv.OtherEarning,0) as LVTotalEarnings
			 , 0 as LVCurrentMonthEarning
			 , 0 as LvMonth1Earning
			 , 0 as LvMonth2Earning
			 , 0 as LvMonth3Earning
			 , 0 as LvMonth4Earning
			 , 0 as LvMonth5Earning
			 , 0 as LvMonth6Earning
			 , 0 as LvMonth7Earning
			 , 0 as LvMonth8Earning
			 , 0 as LvMonth9Earning
			 , 0 as LvMonth10Earning
			 , 0 as LvMonth11Earning
			 , isnull(ltv.CPOSEarning,0)
			 , isnull(ltv.DPOSEarning,0)
			 , isnull(ltv.DDEarning,0)
			 , isnull(ltv.OtherEarning,0)
			 , isnull(ltv.CurrentAnniversaryEarning,0)
			 , isnull(ltv.PreviousAnniversaryEarning,0)
			 , 0 as LvEAYBEarning
			 , Marketable = COALESCE(MarketableByEmail, 0)
			 --, mfdd.PartnerID
			 --, mfdd.TransactionNumber
			 --, mf.MFDDEmail
			 --,	fe.AccountName AS CustomField10
			 --,	mdc.MobileDormant AS CustomField11
		FROM #Fan f   WITH (NOLOCK)
		--INNER JOIN slc_report.dbo.FanCredentials c WITH (NOLOCK) 
		--	ON f.Fanid = c.FanID
		--LEFT JOIN slc_report.Zion.Member_OneClickActivation z WITH (NOLOCK) 
			--ON f.FanID = z.FanID AND COALESCE(z.LinkActive,1) = 1
		LEFT JOIN SmartEmail.TriggerEmailDailyFile_Calculated p2df 
			on f.FanID = p2df.FanID
		LEFT JOIN slc_report..[FanSFDDailyUploadData_DirectDebit] dd 
			on f.FanID = dd.FanID
		LEFT JOIN Staging.SLC_Report_ProductMonitoring pm 
			on f.FanID = pm.FanID
		Left JOIN slc_report.zion.Member_LifeTimeValue as ltv 
			on f.FanID = ltv.FanID
		Left JOIN #Marketable as m 
			on f.FanID = m.fanid
		Left Join #Codes as codes 
			on f.FanID = codes.FanID
		Left Outer join [Relational].[Customers_Reach5GBP] as r 
			on f.FanID = r.FanID

		--LEFT JOIN #MFDD_TriggerEmail mfdd				-- SKY Trigger Email
		--	ON f.FanID = mfdd.FanID						-- SKY Trigger Email
		--LEFT JOIN #MFDD_Email mf
		--	ON f.FanID = mf.FanID
		--LEFT JOIN #FirstEarn fe
		--	ON f.FanID = fe.FanID
		--LEFT JOIN #MobileDormantCustomers mdc
		--	ON f.FanID = mdc.FanID



	/******************************************************************		
			Calculate Delta records
	******************************************************************/

		TRUNCATE TABLE [SmartEmail].[Actito_Deltas]
		
		INSERT INTO [SmartEmail].[Actito_Deltas] ([Email], [FanID], [ClubID], [ClubName], [FirstName], [LastName], [DOB], [Sex], [FromAddress], [FromName], [ClubCashAvailable], [ClubCashPending], [PartialPostCode], [Title], [AgreedTcsDate], [WelcomeEmailCode], [IsDebit], [IsCredit], [Nominee], [RBSNomineeChange], [LoyaltyAccount], [IsLoyalty], [FirstEarnDate], [FirstEarnType], [Reached5GBP], [Homemover], [Day60AccountName], [Day120AccountName], [JointAccount], [FulfillmentTypeID], [CaffeNeroBirthdayCode], [ExpiryDate], [LvTotalEarning], [LvCurrentMonthEarning], [LvMonth1Earning], [LvMonth2Earning], [LvMonth3Earning], [LvMonth4Earning], [LvMonth5Earning], [LvMonth6Earning], [LvMonth7Earning], [LvMonth8Earning], [LvMonth9Earning], [LvMonth10Earning], [LvMonth11Earning], [LvCPOSEarning], [LvDPOSEarning], [LvDDEarning], [LvOtherEarning], [LvCurrentAnniversaryEarning], [LvPreviousAnniversaryEarning], [LvEAYBEarning], [Marketable], [CustomField1], [CustomField2], [CustomField3], [CustomField4], [CustomField5], [CustomField6], [CustomField7], [CustomField8], [CustomField9], [CustomField10], [CustomField11], [CustomField12])
		SELECT * 
		FROM [SmartEmail].[DailyData] 
		EXCEPT 
		SELECT * 
		FROM [SmartEmail].[DailyData_PreviousDay]

		DECLARE @Today_Log DATE = GETDATE()

		IF EXISTS (SELECT 1 FROM [SmartEmail].[Actito_Deltas_Log] WHERE AddedDate = @Today_Log)
			BEGIN

				DELETE
				FROM [SmartEmail].[Actito_Deltas_Log]
				WHERE AddedDate = @Today_Log

			END

		INSERT INTO [SmartEmail].[Actito_Deltas_Log]
		SELECT	*
			,	GETDATE()
		FROM [SmartEmail].[Actito_Deltas]

	/******************************************************************		
			Record customers set to be uploaded to Actito
	******************************************************************/
			
			INSERT INTO [SmartEmail].[Actito_CustomersUploaded]
			SELECT	FanID
				,	AddedDate = GETDATE()
			FROM [SmartEmail].[DailyData] dd
			WHERE NOT EXISTS (	SELECT 1
								FROM [SmartEmail].[Actito_CustomersUploaded] acu
								WHERE dd.FanID = acu.FanID)
			AND NOT EXISTS (SELECT 1
							FROM [SmartEmail].[DailyData_PreviousDay] ddp
							WHERE dd.FanID = ddp.FanID)
		
	COMMIT TRAN

END


