-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.PrePay_PartnerUninvoicedCheck_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT RetailerID AS PartnerID, BalanceStartDate
	FROM APW.RetailerPrePay

	UNION ALL

	SELECT a.PartnerID, r.BalanceStartDate
	FROM APW.RetailerPrePay r
	INNER JOIN APW.PartnerAlternate a ON r.RetailerID = a.AlternatePartnerID

END
