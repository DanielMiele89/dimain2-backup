/******************************************************************************
Author: Ed A
Create date: 23/04/2019
Description:

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[PrePay_RetailerUninvoicedTotal_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT RetailerID, SUM(BalanceAmount) AS UninvoicedTotal
	FROM APW.PrePay_RetailerUninvoicedTotal
	GROUP BY RetailerID;

END