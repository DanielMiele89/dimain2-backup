
CREATE VIEW [Actito].[BurnOffer_Exclusions] 
AS

WITH
Customers AS (	
				SELECT	FanID	
				FROM [Warehouse].[SmartEmail].[PostSFDUploadValidation_FansToBeExcluded]
				UNION ALL
				SELECT	FanID
				FROM [Warehouse].[SmartEmail].[RedeemOfferSlotData] rosd
				WHERE NOT EXISTS (	SELECT 1
									FROM [Warehouse].[SmartEmail].[DataVal_BurnOffer] bo
									WHERE rosd.FanID = bo.FanID_Offer)
				AND NOT EXISTS (SELECT	1
								FROM [SmartEmail].[SampleCustomersList] scl
								WHERE rosd.FanID = scl.FanID)
								)

SELECT	FanID = FanID
	,	EmailSendID = 0	
	,	BurnOfferID_Hero = [RedeemOffer5]
	,	BurnOfferID_2 = [RedeemOffer1]
	,	BurnOfferID_3 = [RedeemOffer2]
	,	BurnOfferID_4 = [RedeemOffer3]
	,	BurnOfferID_5 = [RedeemOffer4]
	,	BurnOfferStartDate_H = ''
	,	BurnOfferStartDate_2 = ''
	,	BurnOfferStartDate_3 = ''
	,	BurnOfferStartDate_4 = ''
	,	BurnOfferStartDate_5 = ''
	,	BurnOfferEndDate_Hero = COALESCE([RedeemOffer5EndDate], '')
	,	BurnOfferEndDate_2 = COALESCE([RedeemOffer1EndDate], '')
	,	BurnOfferEndDate_3 = COALESCE([RedeemOffer2EndDate], '')
	,	BurnOfferEndDate_4 = COALESCE([RedeemOffer3EndDate], '')
	,	BurnOfferEndDate_5  = COALESCE([RedeemOffer4EndDate], '')
FROM [Warehouse].[SmartEmail].[RedeemOfferSlotData] rosd
WHERE EXISTS (	SELECT 1
				FROM Customers cu
				WHERE rosd.FanID = cu.FanID)