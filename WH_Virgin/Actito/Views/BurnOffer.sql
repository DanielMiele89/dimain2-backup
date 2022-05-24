





CREATE VIEW [Actito].[BurnOffer] 
AS

WITH
Customers AS (	
				SELECT	[cu].[FanID]
					,	CASE
							WHEN [cu].[MarketableByEmail] = 0 OR [cu].[CurrentlyActive] = 0 THEN 0
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
				SELECT	[slc].[FanID]	
				FROM [Email].[SampleCustomersList] slc
				WHERE 1 = 1
				AND [slc].[ID] <= 750
				)


SELECT	[FanID] = CONVERT(INT, cu.[FanID])
	,	[EmailSendID] = COALESCE(rosd.[LionSendID], '')

	,	[BurnOfferID_Hero] =	CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_Hero], '')
	,	[BurnOfferID_2] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_1], '')
	,	[BurnOfferID_3] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_2], '')
	,	[BurnOfferID_4] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_3], '')
	,	[BurnOfferID_5] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_4], '')

	,	[BurnOfferStartDate_H] = ''
	,	[BurnOfferStartDate_2] = ''
	,	[BurnOfferStartDate_3] = ''
	,	[BurnOfferStartDate_4] = ''
	,	[BurnOfferStartDate_5] = ''
	
	,	[BurnOfferEndDate_Hero] =	COALESCE([rosd].[RedeemOfferEndDate_Hero], '')
	,	[BurnOfferEndDate_2] =	COALESCE([rosd].[RedeemOfferEndDate_1], '')
	,	[BurnOfferEndDate_3] =	COALESCE([rosd].[RedeemOfferEndDate_2], '')
	,	[BurnOfferEndDate_4] =	COALESCE([rosd].[RedeemOfferEndDate_3], '')
	,	[BurnOfferEndDate_5] =	COALESCE([rosd].[RedeemOfferEndDate_4], '')
FROM Customers cu
INNER JOIN [Email].[RedeemOfferSlotData] rosd
	ON cu.[FanID] = rosd.[FanID]

UNION ALL

SELECT	[FanID] = sa.[FanID]
	,	[EmailSendID] = COALESCE(rosd.[LionSendID], '')
	
	,	[BurnOfferID_Hero] =	CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_Hero], '')
	,	[BurnOfferID_2] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_1], '')
	,	[BurnOfferID_3] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_2], '')
	,	[BurnOfferID_4] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_3], '')
	,	[BurnOfferID_5] =		CONVERT(VARCHAR(64), '')	--	COALESCE([RedeemOfferID_4], '')

	,	[BurnOfferStartDate_H] = ''
	,	[BurnOfferStartDate_2] = ''
	,	[BurnOfferStartDate_3] = ''
	,	[BurnOfferStartDate_4] = ''
	,	[BurnOfferStartDate_5] = ''
	
	,	[BurnOfferEndDate_Hero] =	COALESCE([rosd].[RedeemOfferEndDate_Hero], '')
	,	[BurnOfferEndDate_2] =	COALESCE([rosd].[RedeemOfferEndDate_1], '')
	,	[BurnOfferEndDate_3] =	COALESCE([rosd].[RedeemOfferEndDate_2], '')
	,	[BurnOfferEndDate_4] =	COALESCE([rosd].[RedeemOfferEndDate_3], '')
	,	[BurnOfferEndDate_5] =	COALESCE([rosd].[RedeemOfferEndDate_4], '')
FROM Samples sa
INNER JOIN [Email].[RedeemOfferSlotData] rosd
	ON sa.[FanID] = rosd.[FanID]


GO
DENY SELECT
    ON OBJECT::[Actito].[BurnOffer] TO [New_Insight]
    AS [dbo];

