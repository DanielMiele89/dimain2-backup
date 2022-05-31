-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklySummary_CustomersExposed_AllMember_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @EndDate DATE

	SELECT @EndDate = MAX(WeekEndDate)
	FROM APW.WeeksToProcess

	SELECT r.RetailerID, w.WeekID, COUNT(DISTINCT cu.FanID) AS CardholderCount, CAST(0 AS bit) AS IsCumulative
	FROM Relational.IronOffer o
	LEFT OUTER JOIN apw.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
	INNER JOIN APW.RetailerWS r ON COALESCE(pa.AlternatePartnerID, o.PartnerID) = r.RetailerID
	INNER JOIN APW.WeeksToProcess w ON o.StartDate <= w.WeekEndDate AND (o.EndDate IS NULL OR o.EndDate >= w.WeekStartDate)
	INNER JOIN Relational.Customer cu ON cu.RegistrationDate <= w.WeekEndDate
	LEFT OUTER JOIN APW.PublisherExcludeWS pe ON cu.ClubID = pe.PublisherID and r.RetailerID = pe.RetailerID
		--AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > w.WeekStartDate)
	WHERE pe.ID IS NULL
	AND o.IsAppliedToAllMembers = 1
	GROUP BY r.RetailerID, w.WeekID

	UNION ALL

	SELECT r.RetailerID, CAST(7 AS Tinyint) AS WeekID, COUNT(DISTINCT cu.FanID) AS CardholderCount, CAST(1 AS bit) AS IsCumulative
	FROM Relational.IronOffer o
	LEFT OUTER JOIN apw.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
	INNER JOIN APW.RetailerWS r ON COALESCE(pa.AlternatePartnerID, o.PartnerID) = r.RetailerID
	INNER JOIN Relational.Customer cu ON cu.RegistrationDate <= @EndDate
	LEFT OUTER JOIN APW.PublisherExcludeWS pe ON cu.ClubID = pe.PublisherID and r.RetailerID = pe.RetailerID
	WHERE O.StartDate <=@EndDate AND (O.EndDate IS NULL OR O.EndDate >= R.CumulativeStartDate)
		--AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > R.CumulativeStartDate)
		AND pe.ID IS NULL
		AND O.IsAppliedToAllMembers = 1
	GROUP BY r.RetailerID

END
