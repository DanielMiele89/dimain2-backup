-- =============================================
-- Author:		JEA
-- Create date: 12/04/2016
-- Description:	Retrieves offer members
-- =============================================
CREATE PROCEDURE [APW].[OfferMembers_Fetch] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @NullEndDate DATE
	SET @NullEndDate = DATEADD(DAY, -1,DATEADD(MONTH, 1,DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1))) --Last day of the current month

	SELECT o.ID
		, c.FanID
		, CAST(c.RegistrationDate AS DATE) AS RegistrationDate
		, MAX(i.PartnerID) AS RetailerID
		, MAX(i.ClubID) AS PublisherID
		, CAST(MIN(m.StartDate) AS DATE) AS StartDate
		, ISNULL(CAST(MAX(m.EndDate) AS DATE), @NullEndDate) AS EndDate
	FROM Relational.Offer o
	INNER JOIN Relational.IronOffer i ON o.ID = i.OfferID
	INNER JOIN Relational.IronOfferMember m on i.ID = m.IronOfferID
	INNER JOIN Relational.Customer c ON M.FanID = C.FanID
	GROUP BY o.ID
		, c.FanID
		, c.RegistrationDate

END
