-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklySummary_CustomersExposed_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @EndDate DATE

	SELECT @EndDate = MAX(WeekEndDate)
	FROM APW.WeeksToProcess

	SELECT r.RetailerID, w.WeekID, COUNT(DISTINCT m.CompositeID) AS CardholderCount, CAST(0 AS bit) AS IsCumulative
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID 
	INNER JOIN APW.RetailerWS r ON o.PartnerID = r.RetailerID
	INNER JOIN apw.WeeklySummary_Customer cu ON m.CompositeID = cu.CompositeID
	INNER JOIN APW.WeeksToProcess w ON m.StartDate <= w.WeekEndDate AND (m.EndDate IS NULL OR m.EndDate >= w.WeekStartDate)
		AND cu.ActivationDate <= w.WeekEndDate
		AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > w.WeekStartDate)
	GROUP BY r.RetailerID, w.WeekID

	UNION ALL

	SELECT r.RetailerID, CAST(7 AS Tinyint) AS WeekID, COUNT(DISTINCT m.CompositeID) AS CardholderCount, CAST(1 AS bit) AS IsCumulative
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID 
	INNER JOIN APW.RetailerWS r ON o.PartnerID = r.RetailerID
	INNER JOIN apw.WeeklySummary_Customer cu ON m.CompositeID = cu.CompositeID
	WHERE m.StartDate <=@EndDate AND (m.EndDate IS NULL OR m.EndDate >= R.CumulativeStartDate)
		AND cu.ActivationDate <= @EndDate
		AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > R.CumulativeStartDate)
	GROUP BY r.RetailerID

END
