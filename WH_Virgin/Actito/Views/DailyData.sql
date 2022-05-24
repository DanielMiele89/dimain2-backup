


CREATE VIEW [Actito].[DailyData]
AS

SELECT	v.FanID
	,	'' AS Welcome_Code

	,	[WH_Virgin].[Email].[DailyData].[Birthday_Flag]
	,	[WH_Virgin].[Email].[DailyData].[Birthday_Code]
	,	[WH_Virgin].[Email].[DailyData].[Birthday_CodeExpiryDate]
	,	[WH_Virgin].[Email].[DailyData].[FirstEarn_Date]
	,	[WH_Virgin].[Email].[DailyData].[FirstEarn_Amount] as FirstEarn_TransactionAmount
	,	'' FirstEarn_CashbackAmount
	,	[WH_Virgin].[Email].[DailyData].[FirstEarn_Type]
	,	[WH_Virgin].[Email].[DailyData].[FirstEarn_RetailerName]

	,	[WH_Virgin].[Email].[DailyData].[Reached5GBP_Date]

	,	[WH_Virgin].[Email].[DailyData].[RedeemReminder_Day]
	,	[WH_Virgin].[Email].[DailyData].[RedeemReminder_Amount]

	,	[WH_Virgin].[Email].[DailyData].[EarnConfirmation_Date]

	,	Homemover_Flag = ''

	,	'' as ProductMon_Day60AccountName
	,	'' as ProductMon_Day120AccountName

	,	'' [FulfillmentTypeID]

	,	'' [Reward30_FirstEarnDD]
	,	'' [Reward30_FirstEarnMobile]
	,	'' [Reward30_MobileDormancy]

FROM [WH_Virgin].[Email].[DailyData] v
WHERE EXISTS (	SELECT 1
				FROM [WH_Virgin].[Derived].[Customer] cu
				WHERE cu.FanID = v.FanID)
OR EXISTS (		SELECT 1
				FROM [WH_Virgin].[Email].[SampleCustomersList] scl
				WHERE scl.FanID	 = v.FanID
				AND scl.ID <= 750)


GO
DENY SELECT
    ON OBJECT::[Actito].[DailyData] TO [New_Insight]
    AS [dbo];

