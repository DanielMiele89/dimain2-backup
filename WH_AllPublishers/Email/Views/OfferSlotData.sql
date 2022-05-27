
CREATE VIEW [Email].[OfferSlotData]
AS

SELECT	'Warehouse' AS DatabaseName
	,	FanID
	,	LionSendID
	,	OfferID_Hero = Offer7
	,	OfferID_1 = Offer1
	,	OfferID_2 = Offer2
	,	OfferID_3 = Offer3
	,	OfferID_4 = Offer4
	,	OfferID_5 = Offer5
	,	OfferID_6 = Offer6
	,	OfferID_7 = NULL
	,	OfferID_8 = NULL
	,	OfferStartDate_Hero = Offer7StartDate
	,	OfferStartDate_1 = Offer1StartDate
	,	OfferStartDate_2 = Offer2StartDate
	,	OfferStartDate_3 = Offer3StartDate
	,	OfferStartDate_4 = Offer4StartDate
	,	OfferStartDate_5 = Offer5StartDate
	,	OfferStartDate_6 = Offer6StartDate
	,	OfferStartDate_7 = NULL
	,	OfferStartDate_8 = NULL 
	,	OfferEndDate_Hero = Offer7EndDate
	,	OfferEndDate_1 = Offer1EndDate
	,	OfferEndDate_2 = Offer2EndDate
	,	OfferEndDate_3 = Offer3EndDate
	,	OfferEndDate_4 = Offer4EndDate
	,	OfferEndDate_5 = Offer5EndDate
	,	OfferEndDate_6 = Offer6EndDate
	,	OfferEndDate_7 = NULL
	,	OfferEndDate_8 = NULL
FROM [Warehouse].[SmartEmail].[OfferSlotData]
UNION ALL
SELECT	'WH_Virgin' AS DatabaseName
	,	FanID
	,	LionSendID
	,	OfferID_Hero = OfferID_Hero
	,	OfferID_1 = OfferID_1
	,	OfferID_2 = OfferID_2
	,	OfferID_3 = OfferID_3
	,	OfferID_4 = OfferID_4
	,	OfferID_5 = OfferID_5
	,	OfferID_6 = OfferID_6
	,	OfferID_7 = OfferID_7
	,	OfferID_8 = OfferID_8
	,	OfferStartDate_Hero = OfferStartDate_Hero
	,	OfferStartDate_1 = OfferStartDate_1
	,	OfferStartDate_2 = OfferStartDate_2
	,	OfferStartDate_3 = OfferStartDate_3
	,	OfferStartDate_4 = OfferStartDate_4
	,	OfferStartDate_5 = OfferStartDate_5
	,	OfferStartDate_6 = OfferStartDate_6
	,	OfferStartDate_7 = OfferStartDate_7
	,	OfferStartDate_8 = OfferStartDate_8 
	,	OfferEndDate_Hero = OfferEndDate_Hero
	,	OfferEndDate_1 = OfferEndDate_1
	,	OfferEndDate_2 = OfferEndDate_2
	,	OfferEndDate_3 = OfferEndDate_3
	,	OfferEndDate_4 = OfferEndDate_4
	,	OfferEndDate_5 = OfferEndDate_5
	,	OfferEndDate_6 = OfferEndDate_6
	,	OfferEndDate_7 = OfferEndDate_7
	,	OfferEndDate_8 = OfferEndDate_8
FROM [WH_Virgin].[Email].[OfferSlotData]
UNION ALL
SELECT	'WH_VirginPCA' AS DatabaseName
	,	FanID
	,	LionSendID
	,	OfferID_Hero = OfferID_Hero
	,	OfferID_1 = OfferID_1
	,	OfferID_2 = OfferID_2
	,	OfferID_3 = OfferID_3
	,	OfferID_4 = OfferID_4
	,	OfferID_5 = OfferID_5
	,	OfferID_6 = OfferID_6
	,	OfferID_7 = OfferID_7
	,	OfferID_8 = OfferID_8
	,	OfferStartDate_Hero = OfferStartDate_Hero
	,	OfferStartDate_1 = OfferStartDate_1
	,	OfferStartDate_2 = OfferStartDate_2
	,	OfferStartDate_3 = OfferStartDate_3
	,	OfferStartDate_4 = OfferStartDate_4
	,	OfferStartDate_5 = OfferStartDate_5
	,	OfferStartDate_6 = OfferStartDate_6
	,	OfferStartDate_7 = OfferStartDate_7
	,	OfferStartDate_8 = OfferStartDate_8 
	,	OfferEndDate_Hero = OfferEndDate_Hero
	,	OfferEndDate_1 = OfferEndDate_1
	,	OfferEndDate_2 = OfferEndDate_2
	,	OfferEndDate_3 = OfferEndDate_3
	,	OfferEndDate_4 = OfferEndDate_4
	,	OfferEndDate_5 = OfferEndDate_5
	,	OfferEndDate_6 = OfferEndDate_6
	,	OfferEndDate_7 = OfferEndDate_7
	,	OfferEndDate_8 = OfferEndDate_8
FROM [WH_VirginPCA].[Email].[OfferSlotData]
UNION ALL
SELECT	'WH_Visa' AS DatabaseName
	,	FanID
	,	LionSendID
	,	OfferID_Hero = OfferID_Hero
	,	OfferID_1 = OfferID_1
	,	OfferID_2 = OfferID_2
	,	OfferID_3 = OfferID_3
	,	OfferID_4 = OfferID_4
	,	OfferID_5 = OfferID_5
	,	OfferID_6 = OfferID_6
	,	OfferID_7 = OfferID_7
	,	OfferID_8 = OfferID_8
	,	OfferStartDate_Hero = OfferStartDate_Hero
	,	OfferStartDate_1 = OfferStartDate_1
	,	OfferStartDate_2 = OfferStartDate_2
	,	OfferStartDate_3 = OfferStartDate_3
	,	OfferStartDate_4 = OfferStartDate_4
	,	OfferStartDate_5 = OfferStartDate_5
	,	OfferStartDate_6 = OfferStartDate_6
	,	OfferStartDate_7 = OfferStartDate_7
	,	OfferStartDate_8 = OfferStartDate_8 
	,	OfferEndDate_Hero = OfferEndDate_Hero
	,	OfferEndDate_1 = OfferEndDate_1
	,	OfferEndDate_2 = OfferEndDate_2
	,	OfferEndDate_3 = OfferEndDate_3
	,	OfferEndDate_4 = OfferEndDate_4
	,	OfferEndDate_5 = OfferEndDate_5
	,	OfferEndDate_6 = OfferEndDate_6
	,	OfferEndDate_7 = OfferEndDate_7
	,	OfferEndDate_8 = OfferEndDate_8
FROM [WH_Visa].[Email].[OfferSlotData]

