/******************************************************************************
Author: Ed A
Create date: 23/04/2019
Description:

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_Partner_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT RetailerID AS PartnerID, RetailerID AS RetailerID, BalanceStartDate
	FROM APW.PrePay_Retailer

	UNION ALL

	SELECT pa.PartnerID, r.RetailerID, r.BalanceStartDate
	FROM APW.PrePay_Retailer r
	INNER JOIN APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID;

END