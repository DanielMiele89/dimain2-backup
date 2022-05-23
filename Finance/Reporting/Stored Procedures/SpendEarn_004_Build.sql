CREATE procedure [Reporting].[SpendEarn_004_Build]
as
begin



declare 
    @StartDate date = '2020-01-01'
declare @StartDateTime datetime = @StartDate
,   @PartitionStart int
----------------------------------------------------------------------
-- Get Offers
----------------------------------------------------------------------
drop table if exists #Offers
select
  o.OfferID
, o.PartnerID
, p.PartnerName
into #Offers
from dbo.Offer o
join dbo.Partner p
on o.PartnerID = p.PartnerID
where EndDate >= @StartDate
and PublisherID in (132, 138)
create clustered index CIX on #Offers (OfferID)

----------------------------------------------------------------------
-- Get Offers
----------------------------------------------------------------------
if OBJECT_ID('tempdb..#Es') is not null 
    drop table #Es
select  es.EarningSourceID, es.SourceName, es.SourceTypeID, es.SourceID
into #Es
from earningsource es
where es.EarningSourceID in ('2108','2109','2141','2142')

----------------------------------------------------------------------
-- Get Transactions
----------------------------------------------------------------------

if OBJECT_ID('reporting.SpendEarn_004') is not null 
    drop table reporting.SpendEarn_004

select *
into reporting.SpendEarn_004
from (

select
  es.sourcename as 'partnerName'
, COUNT(DISTINCT CASE WHEN Spend <> 0 THEN tr.CustomerID END) as customersSpending
, COUNT(1) as totalTransactions
, COUNT(DISTINCT CASE WHEN Earning <> 0 THEN tr.CustomerID END) as customersEarning
, SUM(Spend) as totalSpend
, SUM(Earning) as totalEarnings
, MONTH(tr.SourceAddedDateTime) as transactionMonth
, YEAR(tr.SourceAddedDateTime) as transactionYear
, DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0) as first_of_the_month
from 
    dbo.Transactions tr with (nolock)
join 
    #Es es on es.EarningSourceID = tr.EarningSourceID
where  
	TranDate >= @StartDate
	and DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0) >= @StartDateTime
group by
  es.sourcename
, MONTH(tr.SourceAddedDateTime)
, YEAR(tr.SourceAddedDateTime)
, DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0)
UNION
select
  o.partnername as 'partnerName'
, COUNT(DISTINCT CASE WHEN Spend <> 0 THEN tr.CustomerID END) as customersSpending
, COUNT(1) as totalTransactions
, COUNT(DISTINCT CASE WHEN Earning <> 0 THEN tr.CustomerID END) as customersEarning
, SUM(Spend) as totalSpend
, SUM(Earning) as totalEarnings
, MONTH(tr.SourceAddedDateTime) as transactionMonth
, YEAR(tr.SourceAddedDateTime) as transactionYear
, DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0) as first_of_the_month
from 
    dbo.Transactions tr with (nolock)
join 
	#Offers o on o.OfferID = tr.OfferID
where  
	TranDate >= @StartDate
	and DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0) >= @StartDateTime
group by
  o.partnername
, MONTH(tr.SourceAddedDateTime)
, YEAR(tr.SourceAddedDateTime)
, DATEADD(m, DATEDIFF(m, 0, tr.SourceAddedDateTime), 0)
) as tmp
order by
1,7,8,9

end



