-- =============================================
-- Author:		JEA
-- Create date: 07/06/2013
-- Description:	Fetches a list of scheme transactions for incremental load
-- =============================================
CREATE PROCEDURE [Staging].[SchemeTransList_Fetch] 
	--(
	--	@StartMatchID INT
	--)
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT m.ID AS MatchID
		, f.ID AS FanID
		, m.Amount AS Spend
		, CASE WHEN m.Amount < 0 THEN -t.ClubCash ELSE t.ClubCash END as Earnings
		, m.AddedDate
		, pa.BrandID
		, s.CashBackRateNumeric
		, m.AddedDate as AddedDateTime
		, pt.IronOfferID
	FROM	SLC_Report.dbo.Match m WITH (NOLOCK)
			INNER JOIN SLC_Report.dbo.Pan p ON p.ID = m.PanID and p.AffiliateID = 1  --Affiliate ID = 1 means this a scheme run by Reward (rather than e.g. Quidco)
			INNER JOIN SLC_Report.dbo.Fan f ON f.ID = p.UserID
			INNER JOIN SLC_Report.dbo.Trans t ON m.ID = t.MatchID
			INNER JOIN SLC_Report.dbo.RetailOutlet o ON m.RetailOutletID = o.ID
			INNER JOIN Relational.[Partner] pa ON o.PartnerID = pa.PartnerID
			INNER JOIN Relational.Customer c ON c.FanID = f.ID
			INNER JOIN Staging.SchemeCashbackRateInfo s ON m.ID = s.MatchID
			INNER JOIN Relational.PartnerTrans pt on m.ID = pt.MatchID
			WHERE --M.ID > @StartMatchID 	AND 
			f.ClubID in (132, 138)
			AND c.LaunchGroup != 'STF1'
			AND c.LaunchGroup != 'INIT'

END
