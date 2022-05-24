




CREATE VIEW [Email].[vw_EmailDailyData] 
As
SELECT	dd.Email
	,	dd.FanID
	,	dd.PublisherID
	,	dd.CustomerSegment
	,	dd.Title
	,	dd.FirstName
	,	dd.LastName
	,	dd.DOB
	,	dd.CashbackAvailable as ClubCashAvailable
	,	dd.CashbackPending as ClubCashPending
	,	dd.CashbackLTV as ClubCashLTV
	,	dd.PartialPostCode
	,	dd.Marketable
	,	COALESCE(lsco.LionSendID, osd.LionSendID, 0) AS LionSendID
	,	lsd.LionSendName AS LionSendName
	,	osd.OfferID_Hero AS EarnOfferID_Hero
	,	osd.OfferID_1 AS EarnOfferID_1
	,	osd.OfferID_2 AS EarnOfferID_2
	,	osd.OfferID_3 AS EarnOfferID_3
	,	osd.OfferID_4 AS EarnOfferID_4
	,	osd.OfferID_5 AS EarnOfferID_5
	,	osd.OfferID_6 AS EarnOfferID_6
	,	osd.OfferID_7 AS EarnOfferID_7
	,	osd.OfferID_8 AS EarnOfferID_8
	,	osd.OfferStartDate_Hero AS EarnOfferStartDate_Hero
	,	osd.OfferStartDate_1 AS EarnOfferStartDate_1
	,	osd.OfferStartDate_2 AS EarnOfferStartDate_2
	,	osd.OfferStartDate_3 AS EarnOfferStartDate_3
	,	osd.OfferStartDate_4 AS EarnOfferStartDate_4
	,	osd.OfferStartDate_5 AS EarnOfferStartDate_5
	,	osd.OfferStartDate_6 AS EarnOfferStartDate_6
	,	osd.OfferStartDate_7 AS EarnOfferStartDate_7
	,	osd.OfferStartDate_8 AS EarnOfferStartDate_8
	,	osd.OfferEndDate_Hero AS EarnOfferEndDate_Hero
	,	osd.OfferEndDate_1 AS EarnOfferEndDate_1
	,	osd.OfferEndDate_2 AS EarnOfferEndDate_2
	,	osd.OfferEndDate_3 AS EarnOfferEndDate_3
	,	osd.OfferEndDate_4 AS EarnOfferEndDate_4
	,	osd.OfferEndDate_5 AS EarnOfferEndDate_5
	,	osd.OfferEndDate_6 AS EarnOfferEndDate_6
	,	osd.OfferEndDate_7 AS EarnOfferEndDate_7
	,	osd.OfferEndDate_8 AS EarnOfferEndDate_8
	,	rosd.RedeemOfferID_Hero AS BurnOfferID_Hero
	,	rosd.RedeemOfferID_1 AS BurnOfferID_1
	,	rosd.RedeemOfferID_2 AS BurnOfferID_2
	,	rosd.RedeemOfferID_3 AS BurnOfferID_3
	,	rosd.RedeemOfferID_4 AS BurnOfferID_4
	,	rosd.RedeemOfferEndDate_Hero AS BurnOfferEndDate_Hero
	,	rosd.RedeemOfferEndDate_1 AS BurnOfferEndDate_1
	,	rosd.RedeemOfferEndDate_2 AS BurnOfferEndDate_2
	,	rosd.RedeemOfferEndDate_3 AS BurnOfferEndDate_3
	,	rosd.RedeemOfferEndDate_4 AS BurnOfferEndDate_4
	,	dd.Birthday_Flag
	,	dd.Birthday_Code
	,	dd.Birthday_CodeExpiryDate
	,	dd.FirstEarn_Date
	,	dd.FirstEarn_Amount as FirstEarn_TransactionAmount
	, '' as FirstEarn_CashbackAmount
	,	dd.FirstEarn_Type
	,	dd.FirstEarn_RetailerName
	,	dd.Reached5GBP_Date
	,	dd.RedeemReminder_Amount
	,	dd.RedeemReminder_Day
	,	dd.EarnConfirmation_Date
	,	dd.CustomField1
	,	dd.CustomField2
	,	dd.CustomField3
	,	dd.CustomField4
	,	dd.CustomField5
	,	dd.CustomField6
	,	dd.CustomField7
	,	dd.CustomField8
	,	dd.CustomField9
	,	dd.CustomField10
	,	dd.CustomField11
	,	dd.CustomField12
FROM [Email].[DailyData] dd
LEFT JOIN [Email].[LionSend_CustomerOverride] lsco
	ON dd.FanID = lsco.FanID
LEFT JOIN [Email].[OfferSlotData] osd
	ON dd.FanID = osd.FanID
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON dd.FanID = rosd.FanID
	AND osd.LionSendID = rosd.LionSendID
LEFT JOIN [Email].[LionSendDetails] lsd
	ON COALESCE(lsco.LionSendID, osd.LionSendID) = lsd.LionSendID


GO
DENY SELECT
    ON OBJECT::[Email].[vw_EmailDailyData] TO [New_Insight]
    AS [New_DataOps];

