/******************************************************************************
Author: Ed A
Create date: 23/04/2019
Description:

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_RetailerUninvoicedTotal_PANLessTrans_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT 
		p.RetailerID
		, SUM(m.NetAmount) AS Investment
	FROM
		SLC_Report.ras.PANless_Transaction m WITH (NOLOCK)
	INNER JOIN APW.PrePay_Partner p ON m.PartnerID = p.PartnerID
	WHERE 
		m.InvoiceID IS NULL
		AND m.TransactionDate < p.BalanceStartDate
	GROUP BY 
	p.RetailerID;

END