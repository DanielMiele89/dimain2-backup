-- =============================================
-- Author:		JEA
-- Create date: 20/06/2016
-- Description:	Fetches CINs according to their offers
-- =============================================
CREATE PROCEDURE [APW].[SpendPurchaseCount_ExposedCINs_Fetch_20201027]
(
	@PartnerID INT
)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE, @MonthEndDate DATE
	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) -- First day of the last completed month
	SET @MonthEndDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @MonthDate))


    SELECT DISTINCT CIN.CINID
	FROM Relational.IronOfferMember m
	INNER JOIN Relational.IronOffer o ON m.IronOfferID = o.IronOfferID
	INNER JOIN Relational.Customer c ON m.CompositeID = c.CompositeID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	INNER JOIN Relational.CINList CIN ON c.SourceUID = CIN.CIN
	WHERE (COALESCE(m.EndDate, o.EndDate) IS NULL 
	OR COALESCE(m.EndDate, o.EndDate) > @MonthDate)
	AND COALESCE(m.StartDate, o.StartDate) <= @MonthEndDate
	AND o.PartnerID = @PartnerID
	AND c.ActivatedDate < @MonthDate
	AND c.CurrentlyActive = 1
	AND d.CIN IS NULL

END