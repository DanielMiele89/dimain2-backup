
/******************************************************************************
Author:	JEA
Created: 13/10/2016
Purpose: 
	-Loads IronOfferSpendStretch on allPublisherWarehouse

------------------------------------------------------------------------------
Modification History
	
Jason Shipp 04/03/2019
	- Added UNION to query to include MFDD Iron Offer spend stretches from Warehouse.Relational.IronOffer_PartnerCommissionRule_MFDD
	- These values are prioritised over entries for the same Iron Offers in SLC_Report.dbo.PartnerCommissionRule

******************************************************************************/

CREATE PROCEDURE [APW].[DirectLoad_IronOfferSpendStretch_Fetch]
AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT -- MFDDs -- Jason Shipp 04/03/2019
		IronOfferID
		, MAX(RequiredMinimumBasketSize) OVER (PARTITION BY IronOfferID) AS SpendStretchAmount
		FROM Warehouse.Relational.IronOffer_PartnerCommissionRule_MFDD
	WHERE RequiredMinimumBasketSize IS NOT NULL
	AND RequiredMinimumBasketSize > 0

	UNION

	SELECT -- POS Iron Offers
	a.IronOfferID
	, CAST(a.RequiredMinimumBasketSize AS money) AS SpendStretchAmount
	FROM (
			SELECT 
				i.ID AS IronOfferID
				, i.Name AS IronOfferName
				, pcr.CommissionRate AS CashbackRate_Pct
				, pcr.RequiredMinimumBasketSize
				, ROW_NUMBER() OVER(PARTITION BY I.ID ORDER BY pcr.CommissionRate DESC) AS RowNo
			FROM SLC_Report.dbo.IronOffer i
			INNER JOIN SLC_Report.dbo.PartnerCommissionRule pcr
				ON i.ID = pcr.RequiredIronOfferID
			WHERE [status] = 1 
			AND TypeID = 1
	) a
	WHERE RowNo = 1
	AND RequiredMinimumBasketSize IS NOT NULL
	AND RequiredMinimumBasketSize > 0
	AND NOT EXISTS (
		SELECT NULL FROM Warehouse.Relational.IronOffer_PartnerCommissionRule_MFDD dd 
		WHERE a.IronOfferID = dd.IronOfferID AND dd.RequiredMinimumBasketSize > 0
	)
	
	UNION
	
	SELECT	a.IronOfferID	--	Visa Barclaycard
		,	CONVERT(MONEY, a.RequiredMinimumBasketSize) AS SpendStretchAmount
	FROM (	SELECT	iof.IronOfferID
				,	iof.IronOfferName
				,	pcr.CommissionRate AS CashbackRate_Pct
				,	pcr.MinimumBasketSize AS RequiredMinimumBasketSize
				,	ROW_NUMBER() OVER(PARTITION BY iof.IronOfferID ORDER BY pcr.CommissionRate DESC) AS RowNo
			FROM [WH_Visa].[Derived].[IronOffer] iof
			INNER JOIN [WH_Visa].[Derived].[IronOffer_PartnerCommissionRule] pcr
				ON iof.IronOfferID = pcr.IronOfferID
			WHERE [status] = 1 
			AND TypeID = 1) a
	WHERE RowNo = 1
	AND RequiredMinimumBasketSize IS NOT NULL
	AND RequiredMinimumBasketSize > 0

	; -- Avoid duplicating Iron Offers -- Jason Shipp 04/03/2019 (Change ID 1)

END