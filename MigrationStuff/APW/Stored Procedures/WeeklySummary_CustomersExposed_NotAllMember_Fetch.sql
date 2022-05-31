-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.WeeklySummary_CustomersExposed_NotAllMember_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    DECLARE @EndDate DATE

	SELECT @EndDate = MAX(WeekEndDate)
	FROM APW.WeeksToProcess

	SELECT r.RetailerID, w.WeekID, COUNT(DISTINCT m.FanID) AS CardholderCount, CAST(0 AS bit) AS IsCumulative
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.ID 
	LEFT OUTER JOIN apw.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
	INNER JOIN APW.RetailerWS r ON COALESCE(pa.AlternatePartnerID, o.PartnerID) = r.RetailerID
	INNER JOIN Relational.Customer cu ON m.FanID = cu.FanID
	LEFT OUTER JOIN APW.PublisherExcludeWS pe ON cu.ClubID = pe.PublisherID and r.RetailerID = pe.RetailerID
	INNER JOIN APW.WeeksToProcess w ON m.StartDate <= w.WeekEndDate AND (m.EndDate IS NULL OR m.EndDate >= w.WeekStartDate)
		AND cu.RegistrationDate <= w.WeekEndDate
		--AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > w.WeekStartDate)
	WHERE pe.ID IS NULL
	AND o.IsAppliedToAllMembers = 0
	GROUP BY r.RetailerID, w.WeekID

	UNION ALL

	SELECT r.RetailerID, CAST(7 AS Tinyint) AS WeekID, COUNT(DISTINCT m.FanID) AS CardholderCount, CAST(1 AS bit) AS IsCumulative
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.ID
	LEFT OUTER JOIN apw.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
	INNER JOIN APW.RetailerWS r ON COALESCE(pa.AlternatePartnerID, o.PartnerID) = r.RetailerID
	INNER JOIN Relational.Customer cu ON m.FanID = cu.FanID
	LEFT OUTER JOIN APW.PublisherExcludeWS pe ON cu.ClubID = pe.PublisherID and r.RetailerID = pe.RetailerID
	WHERE m.StartDate <=@EndDate AND (m.EndDate IS NULL OR m.EndDate >= R.CumulativeStartDate)
		AND cu.RegistrationDate <= @EndDate
		--AND (cu.DeactivationDate IS NULL OR cu.DeactivationDate > R.CumulativeStartDate)
		AND pe.ID IS NULL
		AND O.IsAppliedToAllMembers = 0
	GROUP BY r.RetailerID

END
