



CREATE VIEW [Actito].[DailyData]
AS

SELECT	FanID = dd.FanID	-- Daily Data

	,	Welcome_Code = COALESCE(dd.[WelcomeEmailCode], '')

	,	Birthday_Flag = ''
	,	Birthday_Code = COALESCE(CAST(dd.CaffeNeroBirthdayCode AS NVARCHAR(255)), '')
	,	Birthday_CodeExpiryDate = ''

	,	FirstEarn_Date = dd.[FirstEarnDate]
	,	FirstEarn_TransactionAmount = CAST('' AS NVARCHAR(24))
	,	FirstEarn_CashbackAmount = ''
	,	FirstEarn_Type = CAST(dd.[FirstEarnType] AS NVARCHAR(255))
	,	FirstEarn_RetailerName = CAST('' AS NVARCHAR(255))

	,	Reached5GBP_Date = dd.[Reached5GBP]

	,	RedeemReminder_Day = ''
	,	RedeemReminder_Amount = CAST('' AS NVARCHAR(24))

	,	EarnConfirmation_Date = ''

	,	Homemover_Flag = dd.[Homemover]

	,	ProductMon_Day60AccountName = COALESCE(dd.[Day60AccountName], '')
	,	ProductMon_Day120AccountName = COALESCE(dd.[Day120AccountName], '')

	,	FulfillmentTypeID = CASE when dd.[FulfillmentTypeID] is NULL then 0 else dd.[FulfillmentTypeID] END

	,	Reward30_FirstEarnDD = COALESCE(fedd.AccountName + ' DD', '')
	,	Reward30_FirstEarnMobile = COALESCE(feml.AccountName + ' ML', '')
	,	Reward30_MobileDormancy =	CASE
										WHEN md.FanID IS NOT NULL THEN 1
										ELSE 0
									END

FROM [Warehouse].[SmartEmail].[DailyData] dd
LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] feml
	ON dd.FanID = feml.FanID
	AND dd.Marketable = 1
	AND feml.FirstEarnType = 'Mobile Login'
	--AND feml.FirstEarnDate in ('2022-04-29', '2022-05-01', CONVERT(DATE, DATEADD(DAY, -1, GETDATE())))
	AND feml.FirstEarnDate = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] fedd
	ON dd.FanID = fedd.FanID
	AND dd.Marketable = 1
	AND fedd.FirstEarnType = 'Direct Debit'
	--AND fedd.FirstEarnDate in ('2022-04-29', '2022-05-01', CONVERT(DATE, DATEADD(DAY, -1, GETDATE())))
	AND fedd.FirstEarnDate = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))
LEFT JOIN [SmartEmail].[TriggerEmail_MobileDormantCustomers] md
	ON dd.FanID = md.FanID
	AND dd.Marketable = 1
	--AND md.MobileDormantDate in ('2022-04-29', '2022-05-01', CONVERT(DATE, DATEADD(DAY, -1, GETDATE())))
	AND md.MobileDormantDate = CONVERT(DATE, GETDATE())

	
	--	WHERE dd.FanID < 1900000000	--	Exclude Sample Customers

--EXCEPT

--SELECT	FanID = dd.FanID	-- Daily Data

--	,	Welcome_Code = COALESCE(dd.[WelcomeEmailCode], '')

--	,	Birthday_Flag = ''
--	,	Birthday_Code = COALESCE(CAST(dd.CaffeNeroBirthdayCode AS NVARCHAR(255)), '')
--	,	Birthday_CodeExpiryDate = ''

--	,	FirstEarn_Date = dd.[FirstEarnDate]
--	,	FirstEarn_TransactionAmount = CAST('' AS NVARCHAR(24))
--	,	FirstEarn_CashbackAmount = ''
--	,	FirstEarn_Type = CAST(dd.[FirstEarnType] AS NVARCHAR(255))
--	,	FirstEarn_RetailerName = CAST('' AS NVARCHAR(255))

--	,	Reached5GBP_Date = dd.[Reached5GBP]

--	,	RedeemReminder_Day = ''
--	,	RedeemReminder_Amount = CAST('' AS NVARCHAR(24))

--	,	EarnConfirmation_Date = ''

--	,	Homemover_Flag = dd.[Homemover]

--	,	ProductMon_Day60AccountName = COALESCE(dd.[Day60AccountName], '')
--	,	ProductMon_Day120AccountName = COALESCE(dd.[Day120AccountName], '')

--	,	FulfillmentTypeID = CASE when dd.[FulfillmentTypeID] is NULL then 0 else dd.[FulfillmentTypeID] END

--	,	Reward30_FirstEarnDD = COALESCE(fedd.AccountName + ' DD', '')
--	,	Reward30_FirstEarnMobile = COALESCE(feml.AccountName + ' ML', '')
--	,	Reward30_MobileDormancy =	CASE
--										WHEN md.FanID IS NOT NULL THEN 1
--										ELSE 0
--									END

--FROM [Warehouse].[SmartEmail].[DailyData_PreviousDay] dd
--LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] feml
--	ON dd.FanID = feml.FanID
--	AND dd.Marketable = 1
--	AND feml.FirstEarnType = 'Mobile Login'
--	AND feml.FirstEarnDate = CONVERT(DATE, DATEADD(DAY, -2, GETDATE()))
--LEFT JOIN [SmartEmail].[TriggerEmail_FirstEarn] fedd
--	ON dd.FanID = fedd.FanID
--	AND dd.Marketable = 1
--	AND fedd.FirstEarnType = 'Direct Debit'
--	AND fedd.FirstEarnDate = CONVERT(DATE, DATEADD(DAY, -2, GETDATE()))
--LEFT JOIN [SmartEmail].[TriggerEmail_MobileDormantCustomers] md
--	ON dd.FanID = md.FanID
--	AND dd.Marketable = 1
--	AND md.MobileDormantDate = CONVERT(DATE, DATEADD(DAY, -1, GETDATE()))




