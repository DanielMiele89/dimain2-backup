-- =============================================
-- Author:		JEA
-- Create date: 06/12/2016
-- Description:	Retrieves transactions from SLC_Report
-- above the highest matchID already retrieved
-- =============================================
CREATE PROCEDURE [APW].[SchemeTrans_Pipe_Fetch] 
	WITH EXECUTE AS 'ProcessOp'
AS
BEGIN

	SET NOCOUNT ON;

	SELECT	m.MatchID,
		m.PublisherID,
		m.FanID,
		m.TranDate,
		m.AddedDate,
		m.Spend,		
		m.Investment,
		COALESCE(pa.AlternatePartnerID,o.PartnerID) AS RetailerID,
	 	LEFT(COALESCE(m.CardHolderPresentData,MCHP.CardholderPresentData),1) CardHolderPresentData,
		o.Channel as OutletChannel,
		m.IronOfferID,
		m.RetailerCashback, 
		ISNULL(COALESCE(pdA.ManagedBy, pdo.ManagedBy),'1') AS DealManagedBy,
		COALESCE(pda.Reward, pdo.Reward) as RewardShare,
		COALESCE(pda.Publisher, pdo.Publisher) as PublisherShare,
		iss.SpendStretchAmount,
		pe.ID AS MonthlyExcludeID,
		ISNULL(ro.IsOnline,0) AS RetailerIsOnline,
		o.OutletID,
		m.PanID,
		qs.SourceUID AS QuidcoSourceUID,
		rc.SchemeMembershipTypeID,
		m.UpstreamMatchID
	FROM	APW.TransPipeStage m WITH (NOLOCK)
			LEFT OUTER JOIN Staging.MatchCardHolderPresent as MCHP on m.MatchID = MCHP.MatchID
			INNER JOIN APW.DirectLoad_RetailOutlet o ON m.RetailOutletID = o.OutletID
			LEFT OUTER JOIN Relational.nFI_Partner_Deals pdo on o.PartnerID = pdo.PartnerID and m.PublisherID = pdo.ClubID and m.TranDate >= pdo.StartDate and (pdo.EndDate is null or m.TranDate <= pdo.EndDate)
			LEFT OUTER JOIN APW.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
			LEFT OUTER JOIN Relational.nFI_Partner_Deals pda on pa.AlternatePartnerID = pda.PartnerID and m.PublisherID = pda.ClubID and m.TranDate >= pda.StartDate and (pda.EndDate is null or m.TranDate <= pda.EndDate)
			LEFT OUTER JOIN APW.DirectLoad_IronOfferSpendStretch iss ON m.IronOfferID = iss.IronOfferID
			LEFT OUTER JOIN APW.PublisherExclude pe ON m.PublisherID = pe.PublisherID AND o.PartnerID = pe.RetailerID AND m.TranDate BETWEEN pe.StartDate AND pe.EndDate
			INNER JOIN APW.DirectLoad_PublisherIDs pu ON m.PublisherID = pu.PublisherID
			LEFT OUTER JOIN APW.DirectLoad_RetailerOnline ro ON o.PartnerID = ro.RetailerID
			LEFT OUTER JOIN (SELECT DISTINCT SourceUID FROM InsightArchive.QuidcoR4GCustomers) qs ON m.SourceUID = qs.SourceUID
			LEFT OUTER JOIN Relational.Customer_SchemeMembership rc ON m.FanID = rc.FanID AND m.TranDate >= rc.StartDate AND (rc.EndDate IS NULL OR m.TranDate < rc.EndDate)

END