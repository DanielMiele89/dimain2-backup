
CREATE VIEW [Actito].[EarnOffer_Exclusions]
AS

WITH
Customers AS (	
				SELECT	FanID	
				FROM [Warehouse].[SmartEmail].[PostSFDUploadValidation_FansToBeExcluded]
				UNION ALL
				SELECT	FanID
				FROM [Warehouse].[SmartEmail].[OfferSlotData] osd
				WHERE NOT EXISTS (	SELECT 1
									FROM [Warehouse].[SmartEmail].[DataVal_EarnOffer] eo
									WHERE osd.FanID = eo.FanID_Offer)
				AND NOT EXISTS (SELECT	1
								FROM [SmartEmail].[SampleCustomersList] scl
								WHERE osd.FanID = scl.FanID)
				)

SELECT	FanID = osd.FanID	-- Earn Offer
	,	EmailSendID = 0
	,	EmailSendName = ''

	,	EarnOfferID_Hero = COALESCE([Offer7], '')
	,	EarnOfferID_1 = COALESCE([Offer1], '')
	,	EarnOfferID_2 = COALESCE([Offer2], '')
	,	EarnOfferID_3 = COALESCE([Offer3], '')
	,	EarnOfferID_4 = COALESCE([Offer4], '')
	,	EarnOfferID_5 = COALESCE([Offer5], '')
	,	EarnOfferID_6 = COALESCE([Offer6], '')
	,	EarnOfferID_7 = CAST('' AS INT)
	,	EarnOfferID_8 = CAST('' AS INT)

	,	EarnOfferStartDate_Hero = COALESCE([Offer7StartDate], '')
	,	EarnOfferStartDate_1 = COALESCE([Offer1StartDate], '')
	,	EarnOfferStartDate_2 = COALESCE([Offer2StartDate], '')
	,	EarnOfferStartDate_3 = COALESCE([Offer3StartDate], '')
	,	EarnOfferStartDate_4 = COALESCE([Offer4StartDate], '')
	,	EarnOfferStartDate_5 = COALESCE([Offer5StartDate], '')
	,	EarnOfferStartDate_6 = COALESCE([Offer6StartDate], '')
	,	EarnOfferStartDate_7 = CAST('' AS DATE)
	,	EarnOfferStartDate_8 = CAST('' AS DATE)

	,	EarnOfferEndDate_Hero = COALESCE([Offer7EndDate], '')
	,	EarnOfferEndDate_1 = COALESCE([Offer1EndDate], '')
	,	EarnOfferEndDate_2 = COALESCE([Offer2EndDate], '')
	,	EarnOfferEndDate_3 = COALESCE([Offer3EndDate], '')
	,	EarnOfferEndDate_4 = COALESCE([Offer4EndDate], '')
	,	EarnOfferEndDate_5 = COALESCE([Offer5EndDate], '')
	,	EarnOfferEndDate_6 = COALESCE([Offer6EndDate], '')
	,	EarnOfferEndDate_7 = CAST('' AS DATE)
	,	EarnOfferEndDate_8 = CAST('' AS DATE)
FROM [Warehouse].[SmartEmail].[OfferSlotData] osd
WHERE EXISTS (	SELECT 1
				FROM Customers cu
				WHERE osd.FanID = cu.FanID)

