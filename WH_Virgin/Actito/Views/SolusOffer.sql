
CREATE VIEW [Actito].[SolusOffer]
AS

WITH
EmailDate AS (	SELECT EmailDate = '2022-04-12'),

Customers AS (	SELECT	cu.[FanID]
					,	cu.[CompositeID]
					,	CASE
							WHEN [cu].[MarketableByEmail] = 0 OR [cu].[CurrentlyActive] = 0 THEN 0
							WHEN se.FanID IS NULL THEN 0
							WHEN se.ControlFlag = 1 THEN 0
							ELSE 1
						END AS ToBeEmailed
				FROM [Derived].[Customer] cu
				INNER JOIN Sandbox.PhillipB.VMMorrisonsApr22TargetControl se
					ON cu.FanID = se.FanID
				WHERE EXISTS (	SELECT 1
								FROM [Email].[Actito_CustomersUploaded] acu
								WHERE cu.FanID = acu.FanID)
				AND NOT EXISTS (SELECT 1
								FROM [Email].[SampleCustomersList] slc
								WHERE cu.FanID = slc.FanID)
				AND se.ControlFlag = 0
				AND CONVERT(DATE, GETDATE()) <= (SELECT EmailDate FROM EmailDate)
				),

EarnOffer AS	(	SELECT	iom.CompositeID
						,	iom.IronOfferID
						,	OfferGUID = iof.HydraOfferID
						,	iom.StartDate
						,	iom.EndDate
					FROM [Derived].[IronOfferMember] iom
					INNER JOIN [Derived].[IronOffer] iof
						ON iom.IronOfferID = iof.IronOfferID
						AND iof.PartnerID = 4263
					WHERE EXISTS (	SELECT 1
									FROM Customers cu
									WHERE iom.CompositeID = cu.[CompositeID]
									AND cu.ToBeEmailed = 1)
					AND iom.EndDate > GETDATE()
					AND CONVERT(DATE, GETDATE()) <= (SELECT EmailDate FROM EmailDate)
				),

Burn AS	(	SELECT	RedeemID = '')


SELECT	FanID = cu.FanID	-- Earn Offer
	,	EarnHeroOfferID =	CONVERT(VARCHAR(255), COALESCE(eo.OfferGUID, '7130E152-A5EB-4F9D-AA60-085B8CC6326F'))
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
	,	BurnHeroOfferID =	CONVERT(VARCHAR(255), COALESCE(bu.RedeemID, ''))
FROM Customers cu
LEFT JOIN EarnOffer eo
	ON cu.CompositeID = eo.CompositeID
CROSS JOIN Burn bu

