-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_RetailerAnnualSPS_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate AS DATE

	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))


	SELECT r.PartnerID AS RetailerID
		, @MonthDate AS MonthDate
		, ISNULL(c.SPS,0) AS ControlSPS
		, ISNULL(e.SPS,0) AS ExposedSPS
	FROM APW.ControlRetailers r
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerSPS WHERE IsControl = 1) c ON r.PartnerID = c.RetailerID
	LEFT OUTER JOIN (SELECT * FROM APW.SpendPurchaseCount_RetailerSPS WHERE IsControl = 0) e ON r.PartnerID = e.RetailerID
	--WHERE r.PartnerID IN (
	--	4138,
	--	4588
	--	)
	ORDER BY RetailerID

END
