-- =============================================
-- Author:		JEA
-- Create date: 01/07/2014
-- Description:	Returns actual commission from partners
-- =============================================
CREATE PROCEDURE [MI].[RetailerProspect_ActualCommission_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @BaseDate DATE, @StartDate DATE, @EndDate DATE

	SET @BaseDate = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)
	SET @StartDate = DATEADD(YEAR, -1, @BaseDate)
	SET @EndDate = DATEADD(DAY, -1, @BaseDate)

    SELECT p.partnerid,P.PartnerName, m.Advertised_Launch_Date AS StartDate, SUM(pt.CommissionChargable) AS Commission 
	FROM Relational.PartnerTrans PT
	INNER JOIN Relational.[Partner] P ON PT.PartnerID = P.PartnerID
	LEFT OUTER JOIN Relational.Master_Retailer_Table m ON p.PartnerID = m.PartnerID
	WHERE pt.TransactionDate BETWEEN @StartDate AND @EndDate
	AND p.PartnerID != 4433
	AND p.PartnerID != 3960
	AND p.PartnerID != 4447
	GROUP BY p.partnerid,P.PartnerName, m.Advertised_Launch_Date
	ORDER BY Commission DESC

END