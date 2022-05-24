



CREATE VIEW [Actito].[BurnOffer] 
AS

WITH
Customers AS (	SELECT	[FanID]	
				FROM [Derived].[Customer] cu
				WHERE cu.[MarketableByEmail] = 1
				AND cu.[CurrentlyActive] = 1
				AND 1 = 1
				),

Samples AS (	
				SELECT	[FanID]
					,	[ID]
				FROM [Email].[SampleCustomersList] scl
				WHERE 1 = 1
				AND ID > 750
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
					) a),

AllCycleDates AS (		
				SELECT	[CycleID]
					,	[StartDate]
					,	[EndDate] = DATEADD(DAY, -14, [EndDate])
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd
				UNION
				SELECT	[CycleID]
					,	[StartDate] = DATEADD(DAY, 14, [StartDate])
					,	[EndDate]
				FROM [Warehouse].[Relational].[ROC_CycleDates] cd2				
				),

CycleDates AS (
				SELECT	MIN(StartDate) AS StartDate
					,	MIN(EndDate) AS EndDate
				FROM AllCycleDates
				WHERE CONVERT(DATE, GETDATE()) <= StartDate
				)

SELECT	[FanID] = CONVERT(INT, cu.[FanID])
	,	[EmailSendID] = COALESCE(rosd.[LionSendID], '')

	,	[BurnOfferID_Hero] =	COALESCE((SELECT CONVERT(VARCHAR(64), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_Hero]), 'CB0B3C27-E26B-4E87-949A-1630D9E6EE87')
	,	[BurnOfferID_2] =		COALESCE((SELECT CONVERT(VARCHAR(64), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_1]), 'CB0B3C27-E26B-4E87-949A-1630D9E6EE87')
	,	[BurnOfferID_3] =		COALESCE((SELECT CONVERT(VARCHAR(64), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_2]), 'CB0B3C27-E26B-4E87-949A-1630D9E6EE87')
	,	[BurnOfferID_4] =		COALESCE((SELECT CONVERT(VARCHAR(64), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_3]), 'CB0B3C27-E26B-4E87-949A-1630D9E6EE87')
	,	[BurnOfferID_5] =		COALESCE((SELECT CONVERT(VARCHAR(64), iof.[RedemptionOfferGUID]) FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_4]), 'CB0B3C27-E26B-4E87-949A-1630D9E6EE87')
	
	,	[BurnOfferStartDate_H]	=	(SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_2]	=	(SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_3]	=	(SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_4]	=	(SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_5]	=	(SELECT StartDate FROM CycleDates)

	,	[BurnOfferEndDate_Hero]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_2]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_3]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_4]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_5]	=	(SELECT EndDate FROM CycleDates)
FROM Customers cu
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON cu.[FanID] = rosd.[FanID]

UNION ALL
				
SELECT	[FanID] = sa.[FanID]
	,	[EmailSendID] = COALESCE(rosd.[LionSendID], '')

	,	[BurnOfferID_Hero] =	CONVERT(VARCHAR(64), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_Hero]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 1), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 1)))
	,	[BurnOfferID_2] =		CONVERT(VARCHAR(64), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_1]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 2), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 2)))
	,	[BurnOfferID_3] =		CONVERT(VARCHAR(64), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_2]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 3), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 3)))
	,	[BurnOfferID_4] =		CONVERT(VARCHAR(64), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_3]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 4), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 4)))
	,	[BurnOfferID_5] =		CONVERT(VARCHAR(64), COALESCE((SELECT iof.[RedemptionOfferGUID] FROM [Derived].[RedemptionOffers] iof WHERE iof.[ID] = rosd.[RedeemOfferID_4]),	(SELECT RedemptionOfferGUID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 5), (SELECT RedemptionOfferGUID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 5)))

	,	[BurnOfferStartDate_H] = (SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_2] = (SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_3] = (SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_4] = (SELECT StartDate FROM CycleDates)
	,	[BurnOfferStartDate_5] = (SELECT StartDate FROM CycleDates)

	,	[BurnOfferEndDate_Hero]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_2]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_3]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_4]	=	(SELECT EndDate FROM CycleDates)
	,	[BurnOfferEndDate_5]	=	(SELECT EndDate FROM CycleDates)
FROM Samples sa
LEFT JOIN [Email].[RedeemOfferSlotData] rosd
	ON sa.[FanID] = rosd.[FanID]

