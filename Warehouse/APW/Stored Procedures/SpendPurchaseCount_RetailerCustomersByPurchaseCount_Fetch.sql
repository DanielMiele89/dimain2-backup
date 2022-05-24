-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RetailerCustomersByPurchaseCount_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate AS DATE

	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))


	SELECT r.PartnerID AS RetailerID
		, @MonthDate AS MonthDate
		, p.TranCount AS PurchaseCount
		, ISNULL(c.CustomerCount,0) AS ControlCount
		, ISNULL(e.CustomerCount,0) AS ExposedCount
	FROM APW.ControlRetailers r
	CROSS JOIN APW.PurchaseCount p
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerPurchaseCount WHERE IsControl = 1) c ON r.PartnerID = c.RetailerID AND p.TranCount =  c.PurchaseCount
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerPurchaseCount WHERE IsControl = 0) e ON r.PartnerID = e.RetailerID AND p.TranCount =  e.PurchaseCount
	--WHERE r.PartnerID IN (
	--	4138,
	--	4588
	--	)
	ORDER BY PurchaseCount, RetailerID

END