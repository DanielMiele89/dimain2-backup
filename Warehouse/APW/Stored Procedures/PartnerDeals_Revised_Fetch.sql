-- =============================================
-- Author:		JEA
-- Create date: 01/12/2016
-- Description:	Fetches partner deals for SchemeTrans population on REWARDBI
-- =============================================
CREATE PROCEDURE [APW].[PartnerDeals_Revised_Fetch]

AS
BEGIN

	SET NOCOUNT ON;

	SELECT 
		p.ID 
		, p.ClubID
		, COALESCE(A.AlternatePartnerID, p.PartnerID) AS PartnerID
		, p.ManagedBy
		, p.StartDate
		, p.EndDate
		, p.[Override]
		, p.Publisher
		, p.Reward
		, p.FixedOverride
	FROM Relational.nFI_Partner_Deals p
	LEFT OUTER JOIN APW.PartnerAlternate a ON p.PartnerID = a.PartnerID

END