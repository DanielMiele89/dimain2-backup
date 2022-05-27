/******************************************************************************
Author: Ed A
Create date: 23/04/2019
Description:

------------------------------------------------------------------------------
Modification History

Jason Shipp 01/04/2020
	- Added condition on join to Warehouse.APW.DirectLoad_OutletOinToPartnerID table to additionally match on PartnerCommissionRuleID for MFDDs (where a PartnerCommissionRuleID exists)
	- To handle Sky, which has multiple Iron Offers on the same DirectDebitOriginatorID

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_RetailerUninvoicedTotal_Match_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT 
		p.RetailerID
		, SUM(m.AffiliateCommissionAmount) AS Investment
	FROM
		SLC_Report.dbo.Match m WITH (NOLOCK)
		INNER JOIN APW.DirectLoad_OutletOinToPartnerID o ON 
			(COALESCE(m.RetailOutletID, m.DirectDebitOriginatorID) = COALESCE(o.OutletID, o.DirectDebitOriginatorID)) 
			AND (o.PartnerCommissionRuleID IS NULL OR m.PartnerCommissionRuleID = o.PartnerCommissionRuleID) -- Fixed by Jason 29/04/2019
		INNER JOIN SLC_Report.dbo.PartnerCommissionRule pcr 
			ON M.PartnerCommissionRuleID = pcr.ID
		INNER JOIN APW.PrePay_Partner p 
			ON o.PartnerID = p.PartnerID
	WHERE 
		m.[status] = 1 
		AND m.rewardstatus IN (0,1)
		AND pcr.TypeID = 2
		AND m.InvoiceID IS NULL
		AND m.TransactionDate < p.BalanceStartDate
	GROUP BY 
		p.RetailerID;

END