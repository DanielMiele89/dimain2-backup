/********************************************************************************************
	Name: SmartEmail.TriggerEmailDailyCalculation_Populate
	Desc: Populates the DailyData table
	Auth: Zoe Taylor

	Change History
			ZT 17/05/2018 - Stored procedure created
				
	
*********************************************************************************************/

CREATE PROCEDURE [SmartEmail].[__TriggerEmailDailyCalculation_Populate_20210510_Archived]
--with Execute as owner	
AS
BEGIN

		DECLARE @Today DATE = GETDATE()
		
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
	2.	Find customers with a birthday today for redemption code
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Birthdays') IS NOT NULL DROP TABLE #Birthdays
		Select FanID
		Into #Birthdays
		From Relational.Customer as c
		Where	Day(GETDATE()) = DAY(DOB) and
				Month(GETDATE()) = Month(DOB) and
				CurrentlyActive = 1
		
		CREATE CLUSTERED INDEX cix_Birthday_FanID on #Birthdays (FanID)

		
/*******************************************************************************************************************************************
	3.	Find batch of codes
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Batches') IS NOT NULL DROP TABLE #Batches
		Select top 2 BatchID
		Into #Batches
		From Relational.RedemptionCodeBatch as a
		Where CodeTypeID = 1
		Order by BatchID Desc

		
/*******************************************************************************************************************************************
	4.	Get list of hardbounced customers
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Hardbounced') IS NOT NULL DROP TABLE #Hardbounced
		Select Email = CAST(Email AS NVARCHAR(100)) -- CJM 20180622 avoids implicit conversion
			, FanID
		Into #Hardbounced
		From Relational.Customer as c
		Where Hardbounced = 1

		CREATE CLUSTERED INDEX cix_Hardbounced_FanID on #Hardbounced (FanID,Email)

		
/*******************************************************************************************************************************************
	5.	Find codes for people with birthdays
*******************************************************************************************************************************************/

		IF OBJECT_ID ('tempdb..#Codes') IS NOT NULL DROP TABLE #Codes
		Select Max(rc.Code) as Code
			, rc.FanID
		Into #Codes
		From Relational.RedemptionCode as rc
		inner join #Batches as b
			on	rc.BatchID = b.BatchID
		inner join #Birthdays as a
			on  rc.FanID = a.FanID
		Group by rc.FanID

		CREATE CLUSTERED INDEX cix_Codes_FanID on #Codes (FanID)

		
/*******************************************************************************************************************************************
	6.	Get customers with valid email addresses
*******************************************************************************************************************************************/


		IF OBJECT_ID ('tempdb..#Fan') IS NOT NULL DROP TABLE #Fan
		SELECT *
		INTO #Fan
		FROM [SLC_Report].[dbo].[Fan] fa
		WHERE fa.ClubID IN (132, 138)
		AND fa.Status = 1
		AND fa.AgreedTCSDate IS NOT NULL
		AND fa.AgreedTCs = 1
		
		CREATE CLUSTERED INDEX CIX_OfflineEmail ON #Fan (OfflineOnly, Email)

		IF OBJECT_ID ('tempdb..#Fans') IS NOT NULL DROP TABLE #Fans
		SELECT	fa.ID AS FanID
			,	fa.Email
			,	fa.FirstName AS [FirstName]
			,	fa.LastName AS [LastName]
			,	fa.ClubCashAvailable
			,	fa.ClubCashPending
			,	Cast(fa.dob AS DATE) AS DOB
			,	fa.Sex
			,	fa.Title
			,	fa.AgreedTCSDate
			,	fa.ClubID
			,	fa.Postcode
		INTO #Fans
		FROM #Fan fa
		WHERE (fa.OfflineOnly = 0  OR fa.OfflineOnly IS NULL)
		AND fa.DeceasedDate IS NULL
		AND Len(fa.Email) >= 9
		AND fa.Email LIKE '%@%._%'
		AND fa.Email NOT LIKE '%@%@%'
		AND RIGHT(fa.Email, 1) NOT IN ('@','.')
		AND LEFT(fa.Email, 1)  NOT IN ('@','.')
		AND fa.Email NOT LIKE '%[:-?]%'
		AND fa.Email NOT LIKE '%[\-^]%'
		AND NOT EXISTS (SELECT 1
						FROM #Hardbounced hb
						WHERE fa.ID = hb.FanID
						AND fa.Email = hb.Email)

		CREATE CLUSTERED INDEX CIX_FanID ON #Fans (FanID)

		
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
			,	1 AS CustomField11
		INTO #MobileDormantCustomers
		FROM [SmartEmail].[TriggerEmail_MobileDormantCustomers] mb
		WHERE mb.MobileDormantDate = @Today
		AND NOT EXISTS (SELECT 1
						FROM #NotMarketable ma
						WHERE mb.FanID = ma.FanID)

		
/*******************************************************************************************************************************************
	11.	Truncate final table and populate with all fields
*******************************************************************************************************************************************/
		

	/******************************************************************		
			Truncate final table and populate with all fields 
	******************************************************************/

		Truncate table [SmartEmail].[DailyData]
		Insert into [SmartEmail].[DailyData] ([Email]
											, [FanID]
											,[ClubID]
											,[ClubName]
											,[FirstName]
											,[LastName]
											,[DOB]
											,[Sex]
											,[FromAddress]
											,[FromName]
											,[ClubCashAvailable]
											,[ClubCashPending]
											,[PartialPostCode]
											,[Title]
											,[AgreedTcsDate]
											,[WelcomeEmailCode]
											,[IsDebit]
											,[IsCredit]
											,[Nominee]
											,[RBSNomineeChange]
											,[LoyaltyAccount]
											,[IsLoyalty]
											,[FirstEarnDate]
											,[FirstEarnType]
											,[Reached5GBP]
											,[Homemover]
											,[Day60AccountName]
											,[Day120AccountName]
											,[JointAccount]
											,[FulfillmentTypeID]
											,[CaffeNeroBirthdayCode]
											,[ExpiryDate]
											,[LvTotalEarning]
											,[LvCurrentMonthEarning]
											,[LvMonth1Earning]
											,[LvMonth2Earning]
											,[LvMonth3Earning]
											,[LvMonth4Earning]
											,[LvMonth5Earning]
											,[LvMonth6Earning]
											,[LvMonth7Earning]
											,[LvMonth8Earning]
											,[LvMonth9Earning]
											,[LvMonth10Earning]
											,[LvMonth11Earning]
											,[LvCPOSEarning]
											,[LvDPOSEarning]
											,[LvDDEarning]
											,[LvOtherEarning]
											,[LvCurrentAnniversaryEarning]
											,[LvPreviousAnniversaryEarning]
											,[LvEAYBEarning]
											,[Marketable]
											,[CustomField7]	-- SKY Trigger Email
											,[CustomField8]	-- SKY Trigger Email
											,[CustomField9]	-- MFDD Trigger Email
											,[CustomField10]	-- First Earn Mobile & Direct Debit Trigger Email
											,[CustomField11]	-- Mobile Dormant Trigger Email
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
			 , p2df.[IsDebit]
			 , p2df.[IsCredit]
			 , Coalesce(CAST(dd.[Nominee] as Bit),0) as Nominee
			 , Coalesce(CAST(dd.[RBSNomineeChange] as Bit),0) as RBSNomineeChange
			 , CAST(p2df.LoyaltyAccount as Bit) as LoyaltyAccount
			 , CAST(p2df.IsLoyalty as Bit) as IsLoyalty
			 , p2df.FirstEarnDate
			 , p2df.FirstEarnType
			 , p2df.Reached5GBP
			 , CAST(p2df.Homemover as Bit) as Homemover
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
			 , Case
					When m.FanID IS null then 1
					Else 0
			   End as Marketable
			 , mfdd.PartnerID
			 , mfdd.TransactionNumber
			 , mf.MFDDEmail
			 ,	fe.AccountName AS CustomField10
			 ,	mdc.CustomField11
		--Into #FinalData
		FROM #Fans f   WITH (NOLOCK)
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
		Left JOIN #NotMarketable as m 
			on f.FanID = m.fanid
		Left Join #Codes as codes 
			on f.FanID = codes.FanID
		Left Outer join [Relational].[Customers_Reach5GBP] as r 
			on f.FanID = r.FanID
		LEFT JOIN #MFDD_TriggerEmail mfdd				-- SKY Trigger Email
			ON f.FanID = mfdd.FanID						-- SKY Trigger Email
		LEFT JOIN #MFDD_Email mf
			ON f.FanID = mf.FanID
		LEFT JOIN #FirstEarn fe
			ON f.FanID = fe.FanID
		LEFT JOIN #MobileDormantCustomers mdc
			ON f.FanID = mdc.FanID

END

---------------------------------------------------------------------------------------------------------------------------------