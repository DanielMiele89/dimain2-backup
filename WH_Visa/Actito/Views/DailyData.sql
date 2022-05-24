



CREATE VIEW [Actito].[DailyData]
AS


SELECT	v.FanID
	,	'' AS Welcome_Code

	,	Birthday_Flag
	,	Birthday_Code
	,	Birthday_CodeExpiryDate
	,	FirstEarn_Date
	,	FirstEarn_Amount as FirstEarn_TransactionAmount
	,	'' FirstEarn_CashbackAmount
	,	FirstEarn_Type
	,	FirstEarn_RetailerName

	,	Reached5GBP_Date

	,	RedeemReminder_Day
	,	RedeemReminder_Amount

	,	EarnConfirmation_Date

	,	Homemover_Flag = ''

	,	'' as ProductMon_Day60AccountName
	,	'' as ProductMon_Day120AccountName

	,	'' [FulfillmentTypeID]

	,	'' [Reward30_FirstEarnDD]
	,	'' [Reward30_FirstEarnMobile]
	,	'' [Reward30_MobileDormancy]

FROM [Email].[DailyData] v
WHERE EXISTS (	SELECT 1
				FROM [Derived].[Customer] cu
				WHERE cu.FanID = v.FanID)
OR EXISTS (		SELECT 1
				FROM [Email].[SampleCustomersList] scl
				WHERE scl.FanID	 = v.FanID)

