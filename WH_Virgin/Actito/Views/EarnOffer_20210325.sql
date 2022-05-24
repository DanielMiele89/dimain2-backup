





CREATE VIEW [Actito].[EarnOffer_20210325]
AS

SELECT	[WH_Virgin].[Email].[OfferSlotData].[FanID]
	,	[WH_Virgin].[Email].[OfferSlotData].[LionSendID] AS EmailSendID 
	,	 '' as EmailSendName
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_Hero] as EarnOfferID_Hero
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_1] as EarnOfferID_1
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_2] as EarnOfferID_2
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_3] as EarnOfferID_3
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_4] as EarnOfferID_4
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_5] as EarnOfferID_5
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_6] as EarnOfferID_6
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_7] as EarnOfferID_7
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferID_8] as EarnOfferID_8
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_Hero] as EarnOfferStartDate_Hero
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_1] as EarnOfferStartDate_1
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_2] as EarnOfferStartDate_2
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_3] as EarnOfferStartDate_3
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_4] as EarnOfferStartDate_4
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_5] as EarnOfferStartDate_5
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_6] as EarnOfferStartDate_6
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_7] as EarnOfferStartDate_7
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferStartDate_8] as EarnOfferStartDate_8
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_Hero] as EarnOfferEndDate_Hero
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_1] as EarnOfferEndDate_1
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_2] as EarnOfferEndDate_2
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_3] as EarnOfferEndDate_3
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_4] as EarnOfferEndDate_4
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_5] as EarnOfferEndDate_5
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_6] as EarnOfferEndDate_6
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_7] as EarnOfferEndDate_7
	,	[WH_Virgin].[Email].[OfferSlotData].[OfferEndDate_8] as EarnOfferEndDate_8
FROM [WH_Virgin].[Email].[OfferSlotData] v
WHERE EXISTS (	SELECT 1
				FROM [WH_Virgin].[Derived].[Customer] cu
				WHERE cu.FanID = v.FanID
				AND cu.MarketableByEmail = 1
				AND cu.CurrentlyActive = 1)
OR EXISTS (		SELECT 1
				FROM [WH_Virgin].[Email].[SampleCustomersList] scl
				WHERE scl.FanID	 = v.FanID)

