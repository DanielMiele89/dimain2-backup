-- =============================================
-- Author:		JEA
-- Create date: 12/06/2018
-- Description:	Returns dataset for RBSOfferCycles report
-- =============================================
CREATE PROCEDURE MI.RBSIronOfferCycleCounts_Fetch 
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT o.IronOfferID AS OfferID
		, o.IronOfferName AS OfferName
		, c.StartDate
		, c.EndDate
		, o.TopCashBackRate
		, p.PartnerID
		, p.PartnerName
		, c.CustomerCount AS ActivatedCount
	FROM Relational.IronOffer o
	INNER JOIN MI.IronOfferCycleCustomerCount c ON O.IronOfferID = C.IronOfferID
	INNER JOIN Relational.[Partner] p ON o.PartnerID = p.PartnerID
	WHERE C.StartDate >= DATEADD(YEAR, -1,CAST(GETDATE() AS DATE))

END