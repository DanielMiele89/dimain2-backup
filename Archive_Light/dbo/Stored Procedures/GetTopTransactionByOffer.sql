CREATE proc GetTopTransactionByOffer
	@IronOfferID int,
	@TopNumber int = 5
as

--GetTopTransactionByOffer 321

set nocount on

select iom.ID
into #IOM
from SLC_Report.dbo.IronOfferMember iom 
inner join SLC_Report.dbo.IronOffer io on iom.IronOfferID = io.ID
where io.ID = @IronOfferID

select top (@TopNumber)
	n.FileID,
	n.RowNum,
	n.MerchantID,
	n.LocationName,
	n.LocationAddress,
	n.LocationCountry,
	n.MCC,
	n.TranDate,
	n.RetailOutletID,
	n.IronOfferMemberID,
	n.MatchID,
	n.BillingRuleID,
	n.MarketingRuleID,
	n.MatchStatus,
	n.FanID,
	n.RewardStatus,
	n.Amount
into #TranReport
from #IOM iom
inner join NobleTransactionHistory n on n.IronOfferMemberID = iom.ID
where n.MatchID is not null and n.MatchStatus = 1 and n.RewardStatus in (0,1)


select 
	@IronOfferID As IronOffer,
	t.FanID,
	convert(varchar(10),convert(date,t.TranDate),103), --t.TranDate
	convert(varchar(10),convert(date,m.AddedDate),103), --m.AddedDate
	t.Amount,
	ro.MerchantID,
	p.Name as [PartnerName],
	pcr_billing.CommissionRate as BillingRate,
	pcr_marketing.CommissionRate as MarketingRate
from #TranReport t
left join SLC_Report.dbo.Match m on t.MatchID = m.ID
left join SLC_Report.dbo.PartnerCommissionRule pcr_billing on pcr_billing.Status = 1 and pcr_billing.TypeID = 2 and t.BillingRuleID = pcr_billing.ID
left join SLC_Report.dbo.PartnerCommissionRule pcr_marketing on pcr_marketing.Status = 1 and pcr_marketing.TypeID = 1 and t.MarketingRuleID = pcr_marketing.ID
left join SLC_Report.dbo.RetailOutlet ro on t.RetailOutletID = ro.ID
left join SLC_Report.dbo.partner p on ro.PartnerID = p.ID

drop table #IOM, #TranReport