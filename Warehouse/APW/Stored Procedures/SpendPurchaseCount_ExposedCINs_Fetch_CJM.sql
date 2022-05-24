-- =============================================
-- Author:		ChrisM
-- Create date: 20/06/2016
-- Description:	Fetches CINs according to their offers
-- Runs in 5s, the original takes over 180s.
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_ExposedCINs_Fetch_CJM]
(
	@PartnerID INT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE, @MonthEndDate DATE
	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) -- First day of the last completed month
	SET @MonthEndDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @MonthDate))

	SELECT CINID
	FROM (SELECT DISTINCT CIN.CINID, c.CompositeID 
		FROM Relational.CINList CIN 
		INNER JOIN Relational.Customer c 
			ON c.SourceUID = CIN.CIN
		WHERE c.ActivatedDate < @MonthDate
			AND c.CurrentlyActive = 1
			AND NOT EXISTS (SELECT 1 FROM MI.CINDuplicate d WHERE c.FanID = d.FanID)
	) c
	WHERE EXISTS (SELECT 1 
		FROM Relational.IronOfferMember m
		INNER JOIN Relational.IronOffer o 
			ON m.IronOfferID = o.IronOfferID
		WHERE m.CompositeID = c.CompositeID
			AND (COALESCE(m.EndDate, o.EndDate) IS NULL OR COALESCE(m.EndDate, o.EndDate) > @MonthDate)
			AND COALESCE(m.StartDate, o.StartDate) <= @MonthEndDate
			AND o.PartnerID = @PartnerID
	)

END


RETURN 0