

CREATE PROCEDURE [Email].[SFD_TriggerEmailCustomers]
AS
BEGIN

DECLARE @Today DATE = GETDATE()

	--	Create Table Of All currently live Redemption Reminder - Value trigger emails
		
		-- CashbackValue is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
		IF OBJECT_ID('tempdb..#RedemptionReminder_Value') IS NOT NULL DROP TABLE #RedemptionReminder_Value
		SELECT tet.ID AS TriggerEmailTypeID
			 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS CashbackValue
		INTO #RedemptionReminder_Value
		FROM [Email].[TriggerEmailType] tet
		CROSS APPLY (	SELECT te.ID
							 , te.TriggerEmail
							 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE tet.ID = te.ID) te1
		CROSS APPLY (	SELECT te.ID
							 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE te1.ID = te.ID) te2
		WHERE tet.TriggerEmail LIKE '%Redemption%Cashback%'
		AND tet.CurrentlyLive = 1


	--	Create Table Of All currently live Redemption Reminder - Value trigger emails
	
		-- DaysSinceEmail is calculated from the Trigger Enail name found in [Email].[TriggerEmailType]
		IF OBJECT_ID('tempdb..#RedemptionReminder_Days') IS NOT NULL DROP TABLE #RedemptionReminder_Days
		SELECT tet.ID AS TriggerEmailTypeID
			 , CONVERT(INT, te2.TriggerEmail_FromFirstNumericUpToNonNumeric) AS DaysSinceEmail
		INTO #RedemptionReminder_Days
		FROM [Email].[TriggerEmailType] tet
		CROSS APPLY (	SELECT te.ID
							 , te.TriggerEmail
							 , SUBSTRING(te.TriggerEmail, PATINDEX('%[0-9]%', te.TriggerEmail), 100) AS TriggerEmail_FromFirstNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE tet.ID = te.ID) te1
		CROSS APPLY (	SELECT te.ID
							 , LEFT(te1.TriggerEmail_FromFirstNumeric, PATINDEX('%[^0-9]%', te1.TriggerEmail_FromFirstNumeric) - 1) AS TriggerEmail_FromFirstNumericUpToNonNumeric
						FROM [Email].[TriggerEmailType] te
						WHERE te1.ID = te.ID) te2
		WHERE tet.TriggerEmail LIKE '%Redemption%Days%'
		AND tet.CurrentlyLive = 1

		CREATE CLUSTERED INDEX CIX_CashbackValue ON #RedemptionReminder_Days (DaysSinceEmail)


IF OBJECT_ID('tempdb..#DailyData') IS NOT NULL DROP TABLE #DailyData
SELECT *
	 , @Today AS EmailSendDate
INTO #DailyData
FROM [Email].[DailyData]
WHERE [Email].[DailyData].[RedeemReminder_Day] IS NOT NULL
OR [Email].[DailyData].[EarnConfirmation_Date] IS NOT NULL

SELECT *
FROM Email.TriggerEmailType


IF OBJECT_ID('tempdb..#TriggerEmailTracking') IS NOT NULL DROP TABLE #TriggerEmailTracking
SELECT [Email].[DailyData].[FanID]
	 , 14 AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , [Email].[DailyData].[Birthday_Code]
	 , [Email].[DailyData].[Birthday_CodeExpiryDate]
	 , NULL AS FirstEarn_RetailerName
	 , NULL AS FirstEarn_Date
	 , NULL AS FirstEarn_Amount
	 , NULL AS FirstEarn_Type
	 , NULL AS Reached5GBP_Date
	 , NULL AS EarnConfirmation_Date
	 , NULL AS RedeemReminder_Amount
	 , NULL AS RedeemReminder_Day
INTO #TriggerEmailTracking
FROM [Email].[DailyData]
WHERE [Email].[DailyData].[Birthday_Flag] IS NOT NULL
UNION
SELECT [dd].[FanID]
	 , 1 AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , NULL AS Birthday_Code
	 , NULL AS Birthday_CodeExpiryDate
	 , dd.FirstEarn_RetailerName
	 , dd.FirstEarn_Date
	 , dd.FirstEarn_Amount
	 , dd.FirstEarn_Type
	 , NULL AS Reached5GBP_Date
	 , NULL AS EarnConfirmation_Date
	 , NULL AS RedeemReminder_Amount
	 , NULL AS RedeemReminder_Day
FROM [Email].[DailyData] dd
WHERE [dd].[FirstEarn_Date] IS NOT NULL
UNION
SELECT [dd].[FanID]
	 , 2 AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , NULL AS Birthday_Code
	 , NULL AS Birthday_CodeExpiryDate
	 , NULL AS FirstEarn_RetailerName
	 , NULL AS FirstEarn_Date
	 , NULL AS FirstEarn_Amount
	 , NULL AS FirstEarn_Type
	 , dd.Reached5GBP_Date
	 , NULL AS EarnConfirmation_Date
	 , NULL AS RedeemReminder_Amount
	 , NULL AS RedeemReminder_Day
FROM [Email].[DailyData] dd
WHERE [dd].[Reached5GBP_Date] IS NOT NULL
UNION
SELECT [Email].[DailyData].[FanID]
	 , 4 AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , NULL AS Birthday_Code
	 , NULL AS Birthday_CodeExpiryDate
	 , NULL AS FirstEarn_RetailerName
	 , NULL AS FirstEarn_Date
	 , NULL AS FirstEarn_Amount
	 , NULL AS FirstEarn_Type
	 , NULL AS Reached5GBP_Date
	 , [Email].[DailyData].[EarnConfirmation_Date]
	 , NULL AS RedeemReminder_Amount
	 , NULL AS RedeemReminder_Day
FROM [Email].[DailyData]
WHERE [Email].[DailyData].[EarnConfirmation_Date] IS NOT NULL
UNION
SELECT FanID
	 , tet.ID AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , NULL AS Birthday_Code
	 , NULL AS Birthday_CodeExpiryDate
	 , NULL AS FirstEarn_RetailerName
	 , NULL AS FirstEarn_Date
	 , NULL AS FirstEarn_Amount
	 , NULL AS FirstEarn_Type
	 , NULL AS Reached5GBP_Date
	 , NULL AS EarnConfirmation_Date
	 , dd.RedeemReminder_Amount
	 , NULL AS RedeemReminder_Day
FROM [Email].[DailyData] dd
INNER JOIN #RedemptionReminder_Value v
	ON dd.RedeemReminder_Amount = v.CashbackValue
INNER JOIN [Email].[TriggerEmailType] tet
	ON v.TriggerEmailTypeID = tet.ID
WHERE RedeemReminder_Day IS NOT NULL
UNION
SELECT FanID
	 , tet.ID AS TriggerEmailTypeID
	 , @Today AS EmailSendDate
	 , NULL AS Birthday_Code
	 , NULL AS Birthday_CodeExpiryDate
	 , NULL AS FirstEarn_RetailerName
	 , NULL AS FirstEarn_Date
	 , NULL AS FirstEarn_Amount
	 , NULL AS FirstEarn_Type
	 , NULL AS Reached5GBP_Date
	 , NULL AS EarnConfirmation_Date
	 , NULL AS RedeemReminder_Amount
	 , dd.RedeemReminder_Day
FROM [Email].[DailyData] dd
INNER JOIN #RedemptionReminder_Days d
	ON dd.RedeemReminder_Day = d.DaysSinceEmail
INNER JOIN [Email].[TriggerEmailType] tet
	ON d.TriggerEmailTypeID = tet.ID

SELECT t.ID
	 , t.TriggerEmail
	 , t.CurrentlyLive
	 , SUM(CASE WHEN tet.FanID IS NULL THEN 0 ELSE 1 END) AS Customers
FROM #TriggerEmailTracking tet
RIGHT JOIN [Email].[TriggerEmailType] t
	ON tet.TriggerEmailTypeID = t.ID
GROUP BY t.ID
	   , t.TriggerEmail
	   , t.CurrentlyLive

SELECT *
FROM [Email].[TriggerEmailType]


INSERT INTO [Email].[TriggerEmailCustomers]
SELECT *
FROM #TriggerEmailTracking


SELECT *
FROM [Email].[TriggerEmailTracking]

/*


	--	Fetch Details of Newsletter Offers

IF OBJECT_ID('tempdb..#OfferSlot') IS NOT NULL DROP TABLE #OfferSlot
SELECT osd.FanID
	 , osd.LionSendID
	 , lsd.LionSendName
	 , osd.OfferHero AS EarnOffer_Hero
	 , osd.Offer1 AS EarnOffer_1
	 , osd.Offer2 AS EarnOffer_2
	 , osd.Offer3 AS EarnOffer_3
	 , osd.Offer4 AS EarnOffer_4
	 , osd.Offer5 AS EarnOffer_5
	 , osd.Offer6 AS EarnOffer_6
	 , osd.Offer7 AS EarnOffer_7
	 , osd.Offer8 AS EarnOffer_8
	 , osd.OfferHeroStartDate AS EarnOfferStartDate_Hero
	 , osd.Offer1StartDate AS EarnOfferStartDate_1
	 , osd.Offer2StartDate AS EarnOfferStartDate_2
	 , osd.Offer3StartDate AS EarnOfferStartDate_3
	 , osd.Offer4StartDate AS EarnOfferStartDate_4
	 , osd.Offer5StartDate AS EarnOfferStartDate_5
	 , osd.Offer6StartDate AS EarnOfferStartDate_6
	 , osd.Offer7StartDate AS EarnOfferStartDate_7
	 , osd.Offer8StartDate AS EarnOfferStartDate_8
	 , osd.OfferHeroEndDate AS EarnOfferEndDate_Hero
	 , osd.Offer1EndDate AS EarnOfferEndDate_1
	 , osd.Offer2EndDate AS EarnOfferEndDate_2
	 , osd.Offer3EndDate AS EarnOfferEndDate_3
	 , osd.Offer4EndDate AS EarnOfferEndDate_4
	 , osd.Offer5EndDate AS EarnOfferEndDate_5
	 , osd.Offer6EndDate AS EarnOfferEndDate_6
	 , osd.Offer7EndDate AS EarnOfferEndDate_7
	 , osd.Offer8EndDate AS EarnOfferEndDate_8
	 , rosd.RedeemOfferHero AS BurnOfferID_Hero
	 , rosd.RedeemOffer1 AS BurnOfferID_1
	 , rosd.RedeemOffer2 AS BurnOfferID_2
	 , rosd.RedeemOffer3 AS BurnOfferID_3
	 , rosd.RedeemOffer4 AS BurnOfferID_4
	 , rosd.RedeemOfferHeroEndDate AS BurnOfferEndDate_Hero
	 , rosd.RedeemOffer1EndDate AS BurnOfferEndDate_1
	 , rosd.RedeemOffer2EndDate AS BurnOfferEndDate_2
	 , rosd.RedeemOffer3EndDate AS BurnOfferEndDate_3
	 , rosd.RedeemOffer4EndDate AS BurnOfferEndDate_4
INTO #OfferSlot
FROM [Email].[OfferSlotData] osd
LEFT JOIN [Email].[LionSendDetails] lsd
	ON osd.LionSendID = lsd.LionSendID
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON osd.FanID = rosd.FanID
	AND osd.LionSendID = rosd.LionSendID

CREATE CLUSTERED INDEX CIX_FanID ON #OfferSlot (FanID)








	 , os.LionSendID
	 , os.LionSendName
	 , os.EarnOffer_Hero
	 , os.EarnOffer_1
	 , os.EarnOffer_2
	 , os.EarnOffer_3
	 , os.EarnOffer_4
	 , os.EarnOffer_5
	 , os.EarnOffer_6
	 , os.EarnOffer_7
	 , os.EarnOffer_8
	 , os.EarnOfferStartDate_Hero
	 , os.EarnOfferStartDate_1
	 , os.EarnOfferStartDate_2
	 , os.EarnOfferStartDate_3
	 , os.EarnOfferStartDate_4
	 , os.EarnOfferStartDate_5
	 , os.EarnOfferStartDate_6
	 , os.EarnOfferStartDate_7
	 , os.EarnOfferStartDate_8
	 , os.EarnOfferEndDate_Hero
	 , os.EarnOfferEndDate_1
	 , os.EarnOfferEndDate_2
	 , os.EarnOfferEndDate_3
	 , os.EarnOfferEndDate_4
	 , os.EarnOfferEndDate_5
	 , os.EarnOfferEndDate_6
	 , os.EarnOfferEndDate_7
	 , os.EarnOfferEndDate_8
	 , os.BurnOfferID_Hero
	 , os.BurnOfferID_1
	 , os.BurnOfferID_2
	 , os.BurnOfferID_3
	 , os.BurnOfferID_4
	 , os.BurnOfferEndDate_Hero
	 , os.BurnOfferEndDate_1
	 , os.BurnOfferEndDate_2
	 , os.BurnOfferEndDate_3
	 , os.BurnOfferEndDate_4


*/

END