




CREATE VIEW [Actito].[BurnOffer] 
AS

WITH
Customers AS (	
				SELECT	[FanID]
					,	CASE
							WHEN [MarketableByEmail] = 0 OR [CurrentlyActive] = 0 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Warehouse].[Relational].[Customer] cu
				WHERE EXISTS (	SELECT 1
								FROM [SmartEmail].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Warehouse].[SmartEmail].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)

				),

Samples AS (	
				SELECT	FanID
					,	ID
				FROM [Warehouse].[SmartEmail].[SampleCustomersList] slc
				WHERE 1 = 1
				),

BOPE AS (	SELECT	PartnerID
				,	RedeemID
				,	CustomerNum
				,	ROW_NUMBER() OVER (PARTITION BY CustomerNum ORDER BY (SELECT NULL)) AS RowNum
				,	PartnerRank
			FROM (	SELECT	PartnerID
						,	RedeemID
						,	(ROW_NUMBER() OVER (ORDER BY PartnerRank, (SELECT NULL)) - 1) / 5 AS CustomerNum
						,	PartnerRank
					FROM (	SELECT	tuv.PartnerID
								,	ri.RedeemID
								,	ROW_NUMBER() OVER (PARTITION BY tuv.PartnerID ORDER BY tuv.TradeUp_Value DESC) AS PartnerRank
							FROM [Relational].[RedemptionItem] ri
							INNER JOIN [Relational].[RedemptionItem_TradeUpValue] tuv
								ON ri.RedeemID = tuv.RedeemID
							WHERE ri.RedeemType = 'Trade Up'
							AND ri.Status = 1) a
					) a
					)

SELECT	FanID = cu.FanID
	,	[EmailSendID] = COALESCE(CASE WHEN [ToBeEmailed] = 0 THEN 0 ELSE rosd.[LionSendID] END, '')
	,	BurnOfferID_Hero =	COALESCE([RedeemOffer5], 7197)
	,	BurnOfferID_2 =		COALESCE([RedeemOffer1], 7197)
	,	BurnOfferID_3 =		COALESCE([RedeemOffer2], 7197)
	,	BurnOfferID_4 =		COALESCE([RedeemOffer3], 7197)
	,	BurnOfferID_5 =		COALESCE([RedeemOffer4], 7197)
	,	BurnOfferStartDate_H = ''
	,	BurnOfferStartDate_2 = ''
	,	BurnOfferStartDate_3 = ''
	,	BurnOfferStartDate_4 = ''
	,	BurnOfferStartDate_5 = ''
	,	BurnOfferEndDate_Hero =	COALESCE([RedeemOffer5EndDate], '')
	,	BurnOfferEndDate_2 =	COALESCE([RedeemOffer1EndDate], '')
	,	BurnOfferEndDate_3 =	COALESCE([RedeemOffer2EndDate], '')
	,	BurnOfferEndDate_4 =	COALESCE([RedeemOffer3EndDate], '')
	,	BurnOfferEndDate_5 =	COALESCE([RedeemOffer4EndDate], '')
FROM Customers cu
LEFT JOIN [Warehouse].[SmartEmail].[RedeemOfferSlotData] rosd
	ON cu.FanID = rosd.FanID

UNION ALL

SELECT	FanID = sa.FanID
	,	EmailSendID = COALESCE(LionSendID, '')
	,	BurnOfferID_Hero =	COALESCE([RedeemOffer5], 	(SELECT RedeemID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 1), (SELECT RedeemID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 1))
	,	BurnOfferID_2 =		COALESCE([RedeemOffer1],	(SELECT RedeemID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 2), (SELECT RedeemID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 2))
	,	BurnOfferID_3 =		COALESCE([RedeemOffer2],	(SELECT RedeemID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 3), (SELECT RedeemID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 3))
	,	BurnOfferID_4 =		COALESCE([RedeemOffer3],	(SELECT RedeemID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 4), (SELECT RedeemID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 4))
	,	BurnOfferID_5 =		COALESCE([RedeemOffer4],	(SELECT RedeemID FROM BOPE WHERE sa.ID % 5 = BOPE.CustomerNum AND BOPE.RowNum = 5), (SELECT RedeemID FROM BOPE WHERE 0 = BOPE.CustomerNum AND BOPE.RowNum = 5))
	,	BurnOfferStartDate_H = ''
	,	BurnOfferStartDate_2 = ''
	,	BurnOfferStartDate_3 = ''
	,	BurnOfferStartDate_4 = ''
	,	BurnOfferStartDate_5 = ''
	,	BurnOfferEndDate_Hero =	COALESCE([RedeemOffer5EndDate], '')
	,	BurnOfferEndDate_2 =	COALESCE([RedeemOffer1EndDate], '')
	,	BurnOfferEndDate_3 =	COALESCE([RedeemOffer2EndDate], '')
	,	BurnOfferEndDate_4 =	COALESCE([RedeemOffer3EndDate], '')
	,	BurnOfferEndDate_5 =	COALESCE([RedeemOffer4EndDate], '')
FROM Samples sa
LEFT JOIN [Warehouse].[SmartEmail].[RedeemOfferSlotData] rosd
	ON sa.FanID = rosd.FanID