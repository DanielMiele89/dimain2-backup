
/*
Author:		Suraj Chahal	
Date:		29th Aug 2013
Purpose:	Update Data In Warehouse.Relational.IronOffer_Campaign_HTM with data for any new offers.
		
		
Change Log:			
					
*/

CREATE PROCEDURE [Staging].[AddingOfferDataTo_IronOffer_Campaign_HTM]
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID ('tempdb..#OfferStats') IS NOT NULL DROP TABLE #OfferStats
SELECT 	ht.ClientServicesRef,
	pcr.PartnerID,
	ht.EPOCU, 
	ht.HTMSegment, 
	ht.IronOfferID,
	pcr.CashbackRate,
	pcr.CommissionRate,
	pcr.AboveBase,
	bo.OfferID as BaseOfferID,
	bo.Base_CashBackRate,
	bo.Base_CommissionRate
INTO #OfferStats
FROM warehouse.relational.IronOffer_Campaign_HTM ht
LEFT OUTER JOIN		(
			SELECT	p.PartnerID,
				RequiredIronOfferID,
				i.StartDate,
				i.EndDate,
				io.AboveBase,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			INNER JOIN slc_report.dbo.IronOffer i
				ON i.ID = p.RequiredIronOfferID
			LEFT OUTER JOIN Warehouse.Relational.IronOffer io
				ON i.ID = io.IronOfferID
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY p.PartnerID, RequiredIronOfferID, i.StartDate, i.EndDate, io.AboveBase
			) pcr
		ON ht.IronOfferID = PCR.RequiredIronOfferID
LEFT OUTER JOIN		(
			SELECT	pb.PartnerID,
				pb.OfferID,
				pb.StartDate, 
				pb.EndDate,
				CAST(CashBackRateNumeric*100 AS REAL) as Base_CashBackRate,
				CAST(MAX(CommissionRate) AS NUMERIC(32,2)) as Base_CommissionRate
			FROM Warehouse.Relational.PartnerOffers_Base pb
			INNER JOIN slc_report.dbo.PartnerCommissionRule pc
				ON pb.OfferID = pc.RequiredIronOfferID
				AND Status = 1
				AND TypeID = 2
			GROUP BY pb.PartnerID,pb.OfferID,pb.StartDate, CashBackRateNumeric,pb.EndDate
			) bo
		ON pcr.PartnerID = bo.PartnerID
		   AND bo.StartDate <= pcr.StartDate
		   AND (bo.EndDate >= pcr.StartDate OR bo.EndDate IS NULL)

--select * from #offerstats order by ironofferid

--Update CashbackRates
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	CashbackRate =
	os.CashbackRate
FROM #offerstats os
INNER JOIN warehouse.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE ht.CashbackRate IS NULL


--Update CommissionRates
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	CommissionRate =
	os.CommissionRate,
	Base_CommissionRate =
	os.Base_CommissionRate
FROM #offerstats os
INNER JOIN warehouse.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE ht.CommissionRate IS NULL


--Update BaseCashbackRate
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	Base_CashbackRate =
	os.Base_CashBackRate
FROM #offerstats os
INNER JOIN warehouse.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE	ht.Base_CashbackRate IS NULL 
	AND ht.PartnerID <> 4337 -- This is because Argos is a Non-Core and does not have a base offer


--Update BaseOfferID
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	BaseOfferID =
	os.BaseOfferID
FROM #offerstats os
INNER JOIN warehouse.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE	ht.BaseOfferID IS NULL 
	AND ht.PartnerID <> 4337 -- This is because Argos is a Non-Core and does not have a base offer


--Update AboveBase
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	AboveBase =
	CASE	
		WHEN Base_CashbackRate IS NULL THEN 1
		WHEN CashbackRate > Base_CashbackRate THEN 1
		ELSE 0
	END
FROM warehouse.relational.IronOffer_Campaign_HTM 
WHERE AboveBase IS NULL



--Updating isConditionalOffer
UPDATE warehouse.relational.IronOffer_Campaign_HTM
SET	isConditionalOffer = 1
FROM slc_report.dbo.PartnerCommissionRule pcr
INNER JOIN warehouse.relational.IronOffer_Campaign_HTM ht
	on pcr.RequiredIronOfferID = ht.IronOfferID
WHERE	pcr.RequiredMerchantID IS NOT NULL OR pcr.RequiredMinimumBasketSize IS NOT NULL

END