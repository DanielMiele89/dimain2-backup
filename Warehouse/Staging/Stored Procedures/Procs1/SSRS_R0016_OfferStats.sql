/*
	Author:			Stuart Barnley
	Date:			23-05-2014

	Description:	This stored procedure is used to populate the report R_0016.

					This is part of the Pre SFD Upload Data Assessment

Update:			N/A
					
*/
Create  Procedure [Staging].[SSRS_R0016_OfferStats]
				  @LionSendID int,@EmailSendDate date
AS

SELECT	COUNT(DISTINCT ItemID) as OffersPromoted,
	COUNT(DISTINCT CASE WHEN CAST(io.StartDate AS DATE) < @EmailSendDate AND (CAST(io.EndDate AS DATE) IS NULL OR io.EndDate > @EmailSendDate) THEN ItemID ELSE NULL END) as Offers_CurrentlyLive,
	COUNT(DISTINCT CASE WHEN CAST(io.StartDate AS DATE) = @EmailSendDate AND (CAST(io.EndDate AS DATE) IS NULL OR io.EndDate > @EmailSendDate) THEN ItemID ELSE NULL END) as Offers_AboutToGoLive,
	COUNT(DISTINCT CASE WHEN io.EndDate <= @EmailSendDate THEN ItemID ELSE NULL END) as Offers_ExpiredByEmailSendDate,
	COUNT(DISTINCT CASE WHEN CAST(io.StartDate AS DATE) > @EmailSendDate THEN ItemID ELSE NULL END) as Offers_NotLiveOnEmailSendDate,
	COUNT(DISTINCT CASE WHEN pcr.CashbackRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCashBackRates,
	COUNT(DISTINCT CASE WHEN pcr.CommissionRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCommissionRates

FROM Warehouse.lion.NominatedLionSendComponent nl
INNER JOIN Warehouse.Relational.IronOffer io
	ON nl.ItemID = io.IronOfferID
	AND io.IsTriggerOffer = 0
LEFT OUTER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
		ON nl.ItemID = PCR.RequiredIronOfferID
WHERE LionSendID = @LionSendID
--SELECT * FROM #OfferStatsTargetted
/*
Union All

SELECT	COUNT(DISTINCT ItemID) as OffersPromoted,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) < @EmailSendDate AND (CAST(iom.EndDate AS DATE) IS NULL OR iom.EndDate > @EmailSendDate)  THEN ItemID ELSE NULL END) as Offers_CurrentlyLive,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) = @EmailSendDate AND (CAST(iom.EndDate AS DATE) IS NULL OR iom.EndDate > @EmailSendDate)  THEN ItemID ELSE NULL END) as Offers_AboutToGoLive,
	COUNT(DISTINCT CASE WHEN iom.EndDate <= @EmailSendDate THEN ItemID ELSE NULL END) as Offers_ExpiredByEmailSendDate,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) > @EmailSendDate THEN ItemID ELSE NULL END) as Offers_NotLiveOnEmailSendDate,
	COUNT(DISTINCT CASE WHEN pcr.CashbackRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCashBackRates,
	COUNT(DISTINCT CASE WHEN pcr.CommissionRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCommissionRates

FROM Warehouse.lion.NominatedLionSendComponent nl
INNER JOIN Warehouse.Relational.IronOffer io
	ON nl.ItemID = io.IronOfferID
	AND io.isTriggerOffer = 1
INNER JOIN Warehouse.Relational.IronOfferMember iom
	ON io.IronOfferID = iom.IronOfferID AND nl.CompositeID = iom.CompositeID 
INNER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
		ON nl.ItemID = PCR.RequiredIronOfferID
WHERE LionSendID = @LionSendID
*/
--SELECT * FROM ##OfferStatsTrigger_IOM
Union All

SELECT	COUNT(DISTINCT ItemID) as OffersPromoted,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) < CAST(GETDATE() AS DATE) AND (CAST(iom.EndDate AS DATE) IS NULL OR iom.EndDate > @EmailSendDate) THEN ItemID ELSE NULL END) as Offers_CurrentlyLive,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) = CAST(GETDATE() AS DATE) AND (CAST(iom.EndDate AS DATE) IS NULL OR iom.EndDate > @EmailSendDate) THEN ItemID ELSE NULL END) as Offers_AboutToGoLive,
	COUNT(DISTINCT CASE WHEN iom.EndDate <= @EmailSendDate THEN ItemID ELSE NULL END) as Offers_ExpiredByEmailSendDate,
	COUNT(DISTINCT CASE WHEN CAST(iom.StartDate AS DATE) > @EmailSendDate THEN ItemID ELSE NULL END) as Offers_NotLiveOnEmailSendDate,
	COUNT(DISTINCT CASE WHEN  pcr.CashbackRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCashBackRates,
	COUNT(DISTINCT CASE WHEN  pcr.CommissionRate IS NOT NULL THEN ItemID ELSE NULL END) as Offers_WithCommissionRates

FROM Warehouse.lion.NominatedLionSendComponent nl
INNER JOIN Warehouse.Relational.IronOffer io
	ON nl.ItemID = io.IronOfferID
	AND io.isTriggerOffer = 1
INNER JOIN Warehouse.iron.TriggerOfferMember iom
	ON io.IronOfferID = iom.IronOfferID AND nl.CompositeID = iom.CompositeID
INNER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END) as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
		ON nl.ItemID = PCR.RequiredIronOfferID
WHERE LionSendID = @LionSendID