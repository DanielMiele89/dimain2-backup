
/*
Author:		Rory Francis
Date:		2019-03-26
Purpose:	Populate Data In nFI.Relational.IronOffer_Campaign_HTM with data for any new offers.
		
		
Change Log:			
					
*/

CREATE PROCEDURE [Staging].[AddingOfferDataTo_IronOffer_Campaign_HTM]

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	

INSERT INTO [nFI].[Relational].[IronOffer_Campaign_HTM] (ClientServicesRef, PartnerID, IronOfferID, isConditionalOffer, isExtension)
SELECT	CampaignCode = cs.CampaignCode
	,	PartnerID= iof.PartnerID
	,	IronOfferID= iof.ID
	,	0
	,	0
FROM [WH_AllPublishers].[Selections].[BriefRequestTool_CampaignSetup] cs
INNER JOIN nFI.Relational.IronOffer iof
	ON cs.IronOfferID = iof.ID
	OR cs.IronOfferID_AlternateRecord = iof.ID
WHERE NOT EXISTS (SELECT 1
				  FROM [nFI].[Relational].[IronOffer_Campaign_HTM] htm
				  WHERE iof.ID = htm.IronOfferID
				  AND cs.CampaignCode = htm.ClientServicesRef)

INSERT INTO [nFI].[Relational].[IronOffer_Campaign_HTM] (ClientServicesRef, PartnerID, IronOfferID, isConditionalOffer, isExtension)
SELECT cd.ClientServicesRef
	 , iof.PartnerID
	 , cd.IronOfferID
	 , 0
	 , 0
FROM Warehouse.Selections.AllPublisher_CampaignDetails cd
INNER JOIN nFI.Relational.IronOffer iof
	ON cd.IronOfferID = iof.ID
WHERE NOT EXISTS (SELECT 1
				  FROM [nFI].[Relational].[IronOffer_Campaign_HTM] htm
				  WHERE cd.IronOfferID = htm.IronOfferID
				  AND cd.ClientServicesRef = htm.ClientServicesRef)

IF OBJECT_ID ('tempdb..#OfferStats') IS NOT NULL DROP TABLE #OfferStats
SELECT 	ht.ClientServicesRef,
	pcr.PartnerID,
	ht.EPOCU, 
	ht.HTMSegment, 
	ht.IronOfferID,
	pcr.CashbackRate,
	pcr.CommissionRate,
	pcr.AboveBase,
	NULL as BaseOfferID,
	NULL AS Base_CashBackRate,
	NULL AS Base_CommissionRate
INTO #OfferStats
FROM nFI.relational.IronOffer_Campaign_HTM ht
LEFT OUTER JOIN		(
			SELECT	p.PartnerID,
				RequiredIronOfferID,
				i.StartDate,
				i.EndDate,
				1 AS AboveBase,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			INNER JOIN slc_report.dbo.IronOffer i
				ON i.ID = p.RequiredIronOfferID
			LEFT OUTER JOIN nFI.Relational.IronOffer io
				ON i.ID = io.OfferID
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY p.PartnerID, RequiredIronOfferID, i.StartDate, i.EndDate
			) pcr
		ON ht.IronOfferID = PCR.RequiredIronOfferID

--select * from #offerstats order by ironofferid

--Update CashbackRates
UPDATE nFI.relational.IronOffer_Campaign_HTM
SET	CashbackRate = os.CashbackRate
FROM #offerstats os
INNER JOIN nFI.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE ht.CashbackRate IS NULL


--Update CommissionRates
UPDATE nFI.relational.IronOffer_Campaign_HTM
SET	CommissionRate =
	os.CommissionRate,
	Base_CommissionRate =
	os.Base_CommissionRate
FROM #offerstats os
INNER JOIN nFI.relational.IronOffer_Campaign_HTM ht
	on os.IronOfferID = ht.IronOfferID
WHERE ht.CommissionRate IS NULL


--Update AboveBase
UPDATE nFI.relational.IronOffer_Campaign_HTM
SET	AboveBase =
	CASE	
		WHEN Base_CashbackRate IS NULL THEN 1
		WHEN CashbackRate > Base_CashbackRate THEN 1
		ELSE 0
	END
FROM nFI.relational.IronOffer_Campaign_HTM 
WHERE AboveBase IS NULL



--Updating isConditionalOffer
UPDATE nFI.relational.IronOffer_Campaign_HTM
SET	isConditionalOffer = 1
FROM slc_report.dbo.PartnerCommissionRule pcr
INNER JOIN nFI.relational.IronOffer_Campaign_HTM ht
	on pcr.RequiredIronOfferID = ht.IronOfferID
WHERE	pcr.RequiredMerchantID IS NOT NULL OR pcr.RequiredMinimumBasketSize IS NOT NULL

-- Updating isExtension
IF OBJECT_ID('tempdb..#Extension') IS NOT NULL DROP TABLE #Extension
SELECT IronOfferID
	 , MIN(ClientServicesRef) AS ClientServicesRef
INTO #Extension
FROM nFI.relational.IronOffer_Campaign_HTM
GROUP BY IronOfferID
HAVING COUNT(*) > 1

UPDATE htm
SET isExtension = 1
FROM nFI.relational.IronOffer_Campaign_HTM htm
INNER JOIN #Extension e
	ON htm.IronOfferID = e.IronOfferID
	AND htm.ClientServicesRef != e.ClientServicesRef

END





