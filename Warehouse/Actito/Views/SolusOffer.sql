
CREATE VIEW [Actito].[SolusOffer]
AS

WITH
EmailDate AS (	SELECT EmailDate = '2022-04-12'),

Customers AS (	SELECT	cu.[FanID]
					,	cu.[CompositeID]
					,	CASE
							WHEN [MarketableByEmail] = 0 OR [CurrentlyActive] = 0 THEN 0
							WHEN se.FanID IS NULL THEN 0
							WHEN se.ControlFlag = 1 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Warehouse].[Relational].[Customer] cu
				INNER JOIN Sandbox.PhillipB.NWGMorrisonsApr22TargetControl_v2 se
					ON cu.FanID = se.FanID
				WHERE EXISTS (	SELECT 1
								FROM [SmartEmail].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Warehouse].[SmartEmail].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)
				AND se.ControlFlag = 0
				AND CONVERT(DATE, GETDATE()) <= (SELECT EmailDate FROM EmailDate)
				),

EarnOffer AS	(	SELECT	iom.CompositeID
						,	iom.IronOfferID
						,	iom.StartDate
						,	iom.EndDate
					FROM [Warehouse].[Relational].[IronOfferMember] iom
					WHERE EXISTS (	SELECT 1
									FROM Customers cu
									WHERE iom.CompositeID = cu.[CompositeID]
									AND cu.ToBeEmailed = 1)
					AND EXISTS (SELECT 1
								FROM [Warehouse].[Relational].[IronOffer] iof
								WHERE iom.IronOfferID = iof.IronOfferID
								AND iof.PartnerID = 4263)
					AND iom.EndDate > GETDATE()
					AND CONVERT(DATE, GETDATE()) <= (SELECT EmailDate FROM EmailDate)
				),

Burn AS	(	SELECT	TOP 1
					ri.RedeemID
				,	ri.PrivateDescription
				,	tuv.TradeUp_Value
			FROM Warehouse.Relational.RedemptionItem_TradeUpValue tuv
			INNER JOIN Warehouse.Relational.RedemptionItem ri
				ON tuv.RedeemID = ri.RedeemID
			WHERE tuv.PartnerID = 4263
			AND CONVERT(DATE, GETDATE()) <= (SELECT EmailDate FROM EmailDate))


SELECT	FanID = cu.FanID	-- Earn Offer
	,	EarnHeroOfferID =	COALESCE(eo.IronOfferID, 8495)
	,	EarnHeroOfferStartDate =	CASE
										WHEN cu.[ToBeEmailed] = 0 THEN NULL
										WHEN eo.StartDate IS NULL THEN NULL
										ELSE CONVERT(DATE, '2022-04-12')	--		eo.StartDate
									END
	,	EarnHeroOfferEndDate =		CASE
										WHEN cu.[ToBeEmailed] = 0 THEN NULL
										WHEN eo.StartDate IS NULL THEN NULL
										ELSE CONVERT(DATE, eo.EndDate)
									END	
	,	BurnHeroOfferID =	COALESCE(bu.RedeemID, 7197)
FROM Customers cu
LEFT JOIN EarnOffer eo
	ON cu.CompositeID = eo.CompositeID
CROSS JOIN Burn bu

