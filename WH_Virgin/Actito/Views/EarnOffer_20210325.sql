





CREATE VIEW [Actito].[EarnOffer_20210325]
AS

SELECT	FanID
	,	LionSendID AS EmailSendID 
	,	 '' as EmailSendName
	,	[OfferID_Hero] as EarnOfferID_Hero
	,	[OfferID_1] as EarnOfferID_1
	,	[OfferID_2] as EarnOfferID_2
	,	[OfferID_3] as EarnOfferID_3
	,	[OfferID_4] as EarnOfferID_4
	,	[OfferID_5] as EarnOfferID_5
	,	[OfferID_6] as EarnOfferID_6
	,	[OfferID_7] as EarnOfferID_7
	,	[OfferID_8] as EarnOfferID_8
	,	[OfferStartDate_Hero] as EarnOfferStartDate_Hero
	,	[OfferStartDate_1] as EarnOfferStartDate_1
	,	[OfferStartDate_2] as EarnOfferStartDate_2
	,	[OfferStartDate_3] as EarnOfferStartDate_3
	,	[OfferStartDate_4] as EarnOfferStartDate_4
	,	[OfferStartDate_5] as EarnOfferStartDate_5
	,	[OfferStartDate_6] as EarnOfferStartDate_6
	,	[OfferStartDate_7] as EarnOfferStartDate_7
	,	[OfferStartDate_8] as EarnOfferStartDate_8
	,	[OfferEndDate_Hero] as EarnOfferEndDate_Hero
	,	[OfferEndDate_1] as EarnOfferEndDate_1
	,	[OfferEndDate_2] as EarnOfferEndDate_2
	,	[OfferEndDate_3] as EarnOfferEndDate_3
	,	[OfferEndDate_4] as EarnOfferEndDate_4
	,	[OfferEndDate_5] as EarnOfferEndDate_5
	,	[OfferEndDate_6] as EarnOfferEndDate_6
	,	[OfferEndDate_7] as EarnOfferEndDate_7
	,	[OfferEndDate_8] as EarnOfferEndDate_8
FROM [WH_Virgin].[Email].[OfferSlotData] v
WHERE EXISTS (	SELECT 1
				FROM [WH_Virgin].[Derived].[Customer] cu
				WHERE cu.FanID = v.FanID
				AND cu.MarketableByEmail = 1
				AND cu.CurrentlyActive = 1)
OR EXISTS (		SELECT 1
				FROM [WH_Virgin].[Email].[SampleCustomersList] scl
				WHERE scl.FanID	 = v.FanID)

