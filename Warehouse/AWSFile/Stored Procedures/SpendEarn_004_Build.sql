CREATE procedure [AWSFile].[SpendEarn_004_Build]
as 
begin
set xact_abort on



 if OBJECT_ID('tempdb..#tempIron') is not null
	drop table #tempIron
select	iof.ID as ironOfferID,
		iof.PartnerID as partnerID,
		cast(iof.StartDate as date) as ironOfferStartDate,
		cast(iof.EndDate as date) as ironOfferEndDate,
		ioc.ClubID as clubID,
		ioc.ID as ironOfferClubID,
		pn.Name as partnerName
		into #tempIron
from [SLC_REPL].[dbo].[IronOffer] as iof
left join [SLC_REPL].[dbo].[IronOfferClub] as ioc on ioc.IronOfferID = iof.ID
left join [SLC_REPL].[dbo].[Partner] as pn on pn.ID = iof.PartnerID
where ioc.ClubID = 132
and iof.EndDate >= '2019-01-01'
create clustered index cix on #tempIron(ironOfferID)

;

 if OBJECT_ID('tempdb..#fanID') is not null
	drop table #fanID
select	fn.ID
		into #fanID
from [SLC_REPL].[dbo].[Fan] fn
where fn.ClubID IN (132, 138)
create clustered index cix on #fanID(ID);

;

/*
if OBJECT_ID('tempdb..#EarningSource') is not null 
	drop table #EarningSource
select	ID, 
		sp.[Description]
into #EarningSource
from [SLC_REPL].[dbo].[SLCPoints] sp -- AdditionalCashbackAdjustment
where ID IN (57, 58, 91, 90)
create clustered index cix on #EarningSource (ID)
*/
;

--begin transaction
 if OBJECT_ID('awsfile.SpendEarn_004') is not null
	drop table awsfile.SpendEarn_004
;
with financials as (
select	ti.partnerName,
		COUNT(DISTINCT(fn.ID)) as customersSpending,
		COUNT(DISTINCT(tr.ID)) as totalTransactions,
		COUNT(DISTINCT(fn.ID)) as customersEarning,
		SUM(tr.Price * tt.Multiplier) as totalSpend,
		SUM(tr.ClubCash * tt.Multiplier) as totalEarnings,
		Month(tr.ProcessDate) as transactionMonth,
		Year(tr.ProcessDate) as transactionYear,
		DATEADD(m, DATEDIFF(m, 0, tr.ProcessDate), 0) as first_of_the_month
from [SLC_REPL].[dbo].[Trans] as tr
inner join [SLC_REPL].[dbo].[PartnerCommissionRule] as pcr on pcr.ID = tr.PartnerCommissionRuleID
inner join #fanID as fn on fn.ID = tr.FanID
inner join #tempIron as ti on ti.ironOfferID = pcr.RequiredIronOfferID
inner join [SLC_REPL].[dbo].TransactionType tt ON tt.ID = tr.TypeID
where tr.Date >= '2019-02-01'
and tr.PartnerCommissionRuleID <> ''
and pcr.RequiredIronOfferID <> ''
and tt.Multiplier <> 0
group by ti.partnerName, Month(tr.ProcessDate), Year(tr.ProcessDate), DATEADD(m, DATEDIFF(m, 0, tr.ProcessDate), 0)
)

select	fin.partnerName,
		fin.transactionYear,
		fin.transactionMonth,
		fin.first_of_the_month,
		fin.customersSpending,
		fin.totalTransactions,
		fin.totalSpend,
		fin.customersEarning,
		fin.totalEarnings,
		fin.totalEarnings / fin.totalSpend as cashbackRate
		into awsfile.SpendEarn_004
from financials as fin

commit transaction
end




GO
GRANT EXECUTE
    ON OBJECT::[AWSFile].[SpendEarn_004_Build] TO [Process_AWS_SpendEarn]
    AS [dbo];

