

CREATE VIEW [Actito].[BurnOffer] 
AS

WITH
Customers AS (	
				SELECT	[FanID]
					,	CASE
							WHEN [MarketableByEmail] = 0 OR [EmailTracking] = 0 OR [CurrentlyActive] = 0 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Derived].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [Email].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Email].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)
				),

Samples AS (	
				SELECT	[FanID]
					,	[ID]
				FROM [Email].[SampleCustomersList] scl
				WHERE 1 = 1
				),

BOPE AS (	SELECT	RedemptionPartnerGUID
				,	RedeemID
				,	RedemptionOfferGUID
				,	CustomerNum
				,	ROW_NUMBER() OVER (PARTITION BY CustomerNum ORDER BY (SELECT NULL)) AS RowNum
				,	PartnerRank
			FROM (	SELECT	RedemptionPartnerGUID
						,	RedeemID
						,	RedemptionOfferGUID
						,	(ROW_NUMBER() OVER (ORDER BY PartnerRank, (SELECT NULL)) - 1) / 5 AS CustomerNum
						,	PartnerRank
					FROM (	SELECT	ro.RedemptionPartnerGUID
								,	ro.ID AS RedeemID
								,	ro.RedemptionOfferGUID
								,	ROW_NUMBER() OVER (PARTITION BY ro.RedemptionPartnerGUID ORDER BY ro.TradeUp_CashbackRequired DESC) AS PartnerRank
							FROM [Derived].[RedemptionOffers] ro
							WHERE ro.Status = 'Live'
							AND ro.TradeUp_CashbackRequired > 0) a
					) a
					)

SELECT	[FanID] = cu.[FanID]
	,	[EmailSendID] = COALESCE(CASE WHEN [ToBeEmailed] = 0 THEN 0 ELSE rosd.[LionSendID] END, '')

	,	[BurnOfferID_Hero] =	COALESCE((SELECT CONVERT(VARCHAR(255), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_Hero]), '5823654F-1C5B-4E93-94EC-E75FCC5F07FB')
	,	[BurnOfferID_2] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_1]), '5823654F-1C5B-4E93-94EC-E75FCC5F07FB')
	,	[BurnOfferID_3] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_2]), '5823654F-1C5B-4E93-94EC-E75FCC5F07FB')
	,	[BurnOfferID_4] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_3]), '5823654F-1C5B-4E93-94EC-E75FCC5F07FB')
	,	[BurnOfferID_5] =		COALESCE((SELECT CONVERT(VARCHAR(255), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_4]), '5823654F-1C5B-4E93-94EC-E75FCC5F07FB')

	,	[BurnOfferStartDate_H] = ''
	,	[BurnOfferStartDate_2] = ''
	,	[BurnOfferStartDate_3] = ''
	,	[BurnOfferStartDate_4] = ''
	,	[BurnOfferStartDate_5] = ''

	,	[BurnOfferEndDate_Hero] = rosd.[RedeemOfferEndDate_Hero]
	,	[BurnOfferEndDate_2] = rosd.[RedeemOfferEndDate_1]
	,	[BurnOfferEndDate_3] = rosd.[RedeemOfferEndDate_2]
	,	[BurnOfferEndDate_4] = rosd.[RedeemOfferEndDate_3]
	,	[BurnOfferEndDate_5] = rosd.[RedeemOfferEndDate_4]
FROM Customers cu
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON cu.[FanID] = rosd.[FanID]

UNION ALL
				
SELECT	[FanID] = sa.[FanID]
	,	[EmailSendID] = COALESCE(rosd.[LionSendID], 0)

	,	[BurnOfferID_Hero] =	CONVERT(VARCHAR(255), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_Hero]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 1), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 1)))
	,	[BurnOfferID_2] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_1]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 2), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 2)))
	,	[BurnOfferID_3] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_2]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 3), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 3)))
	,	[BurnOfferID_4] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_3]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 4), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 4)))
	,	[BurnOfferID_5] =		CONVERT(VARCHAR(255), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_4]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 5), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 5)))

	,	[BurnOfferStartDate_H] = ''
	,	[BurnOfferStartDate_2] = ''
	,	[BurnOfferStartDate_3] = ''
	,	[BurnOfferStartDate_4] = ''
	,	[BurnOfferStartDate_5] = ''

	,	[BurnOfferEndDate_Hero] = rosd.[RedeemOfferEndDate_Hero]
	,	[BurnOfferEndDate_2] = rosd.[RedeemOfferEndDate_1]
	,	[BurnOfferEndDate_3] = rosd.[RedeemOfferEndDate_2]
	,	[BurnOfferEndDate_4] = rosd.[RedeemOfferEndDate_3]
	,	[BurnOfferEndDate_5] = rosd.[RedeemOfferEndDate_4]
FROM Samples sa
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON sa.[FanID] = rosd.[FanID]

