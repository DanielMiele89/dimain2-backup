-- =============================================
-- Author:		JEA
-- Create date: 06/12/2016
-- Description:	Retrieves transactions from SLC_Report
-- above the highest matchID already retrieved
-- =============================================
create PROCEDURE [APW].[DirectLoad_SchemeTrans_Incremental_OLD] 
	(
		@MatchID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

	SELECT	m.ID AS MatchID,
		f.ClubID AS PublisherID,
		f.ID AS FanID,
		CAST(m.TransactionDate AS DATE) AS TranDate,
		CAST(m.AddedDate AS DATE) AS AddedDate,
		m.Amount AS Spend,		
		m.AffiliateCommissionAmount AS Investment,
		COALESCE(pa.AlternatePartnerID,o.PartnerID) AS RetailerID,
	 	LEFT(COALESCE(m.CardHolderPresentData,MCHP.CardholderPresentData),1) CardHolderPresentData,
		o.Channel as OutletChannel,
		pcr.RequiredIronOfferID AS IronOfferID,
		ISNULL(t.ClubCash * tt.Multiplier,0) AS RetailerCashback, 
		ISNULL(pd.Exclude,0) AS NotRewardManaged,
		pd.RewardShare,
		pd.PublisherShare,
		iss.SpendStretchAmount,
		pe.ID AS MonthlyExcludeID,
		ISNULL(ro.IsOnline,0) AS RetailerIsOnline,
		o.OutletID,
		m.PanID
	FROM	SLC_Report.dbo.Match m WITH (NOLOCK)
			INNER JOIN slc_report.dbo.Trans t WITH (NOLOCK) ON t.MatchID = m.ID
			INNER JOIN SLC_report.dbo.Fan f ON t.FanID = f.ID
			LEFT OUTER JOIN Staging.MatchCardHolderPresent as MCHP on t.MatchID = MCHP.MatchID
			INNER JOIN APW.DirectLoad_RetailOutlet o ON m.RetailOutletID = o.OutletID
			INNER JOIN slc_report.dbo.PartnerCommissionRule pcr ON M.PartnerCommissionRuleID = pcr.ID
			LEFT OUTER JOIN SLC_Report.dbo.TransactionType tt ON t.TypeID = tt.ID
			LEFT OUTER JOIN APW.DirectLoad_PartnerDeals pd ON f.ClubID = pd.PublisherID AND o.PartnerID = pd.PartnerID AND m.TransactionDate BETWEEN pd.StartDate AND pd.EndDate
			LEFT OUTER JOIN APW.PartnerAlternate pa ON o.PartnerID = pa.PartnerID
			LEFT OUTER JOIN APW.DirectLoad_IronOfferSpendStretch iss ON pcr.RequiredIronOfferID = iss.IronOfferID
			LEFT OUTER JOIN APW.PublisherExclude pe ON f.ClubID = pe.PublisherID AND o.PartnerID = pe.RetailerID AND m.TransactionDate BETWEEN pe.StartDate AND pe.EndDate
			INNER JOIN APW.DirectLoad_PublisherIDs pu ON f.ClubID = pu.PublisherID
			LEFT OUTER JOIN APW.DirectLoad_RetailerOnline ro ON o.PartnerID = ro.RetailerID
	WHERE m.[status] = 1 and m.rewardstatus in (0,1)
	AND pcr.TypeID = 2
	AND m.TransactionDate >= '2012-01-01'
	AND o.PartnerID != 4433
	AND o.PartnerID != 4447
	AND m.ID > @MatchID

END