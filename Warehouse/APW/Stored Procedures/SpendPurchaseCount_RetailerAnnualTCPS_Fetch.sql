-- =============================================
-- Author:		JEA
-- Create date: 28/09/2016
-- Description:	Retrieves annual tran count
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RetailerAnnualTCPS_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate AS DATE

	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))


	SELECT r.PartnerID AS RetailerID
		, @MonthDate AS MonthDate
		, ISNULL(c.AvgPurchases,0) AS ControlTCPS
		, ISNULL(e.AvgPurchases,0) AS ExposedTCPS
	FROM APW.ControlRetailers r
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerAvgPurchases WHERE IsControl = 1) c ON r.PartnerID = c.RetailerID
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerAvgPurchases WHERE IsControl = 0) e ON r.PartnerID = e.RetailerID
	--WHERE r.PartnerID IN (
	--	4138,
	--	4588
	--	)
	ORDER BY RetailerID

END
