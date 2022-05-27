/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

Update:			N/A
					
*/
Create Procedure [Staging].[SSRS_R0016_OffersWithConditions]
				 @LionSendID int
As
IF OBJECT_ID ('tempdb..#ConditionalOffers') IS NOT NULL DROP TABLE #ConditionalOffers

SELECT	DISTINCT 
	ItemID as OfferID,
	io.IronOfferName,
	MID_Condition,
	SpendStretch_Condition
FROM Warehouse.lion.NominatedLionSendComponent nl
LEFT OUTER JOIN Warehouse.Relational.IronOffer io
	ON nl.ItemID = io.IronOfferID
LEFT OUTER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN RequiredMerchantID IS NOT NULL THEN 'Y' ELSE 'N' END) as MID_Condition,
				MAX(CASE WHEN RequiredMinimumBasketSize IS NOT NULL THEN 'Y' ELSE 'N' END) as SpendStretch_Condition
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
		ON nl.ItemID = PCR.RequiredIronOfferID
WHERE	LionSendID = @LionSendID
	AND (MID_Condition = 'Y' AND SpendStretch_Condition = 'Y' OR MID_Condition = 'Y' OR SpendStretch_Condition = 'Y')