
 CREATE PROCEDURE [WilliamA].[SwitchDummyDataSet]
AS
BEGIN


SET NOCOUNT ON

IF OBJECT_ID('tempdb..#sample') IS NOT NULL 
DROP TABLE #sample
select distinct top 100000 fanid,postcode,Region,PostCodeDistrict
into #sample
from Warehouse.relational.customer
where postcode != ''
AND PostArea !='BT'
AND Unsubscribed = 0

--Clicked on Offer

IF OBJECT_ID('tempdb..#clickedOnOffer') IS NOT NULL 
DROP TABLE #clickedOnOffer
;with clickedOnOffer as (
	select  top 10 percent FanID
		,	1 as clickedOnOffer
	from #sample
--	order by NEWID()
), notclickedOnOffer as (
	select FanID
	,	0 as clickedOnOffer
	from #sample
	where FanID NOT IN (
						select FanID
						from clickedOnOffer
						)
)
select *
into #clickedOnOffer
from clickedOnOffer
union all 
select *
from notclickedOnOffer


--How many progressed
IF OBJECT_ID('tempdb..#HowManyProgressed') IS NOT NULL 
DROP TABLE #HowManyProgressed
;with HowManyProgressed as (
	select  top 70 percent fanid
		,	1 as progressed
	from #clickedOnOffer
	where clickedOnOffer = 1
	--order by NEWID()
), NotHowManyProgressed as (
	select FanID
	,	0 as progressed
	from #sample
	where FanID NOT IN (
						select FanID
						from HowManyProgressed
						)
)
select *
into #HowManyProgressed
from HowManyProgressed
union all 
select *
from NotHowManyProgressed

--How many customers confirmed switch

IF OBJECT_ID('tempdb..#HowManySwitched') IS NOT NULL 
DROP TABLE #HowManySwitched
;with ConfirmedSwitch as (
	select  top 60 percent FanID
		,	1 as switched
		,	dateadd(day, (abs(CHECKSUM(newid())) % 170) * -1, getdate()) as dateSwitched
	from #HowManyProgressed
	where progressed = 1
	--order by NEWID()
), notConfirmedSwitch as (
	select FanID
	,	0 as clickedOnOffer
	,	null as dateSwitched
	,	null as dateCompleted
	from #sample
	where FanID NOT IN (
						select FanID
						from ConfirmedSwitch
						)
), CompletedSwitch as (
	select FanID,switched,dateSwitched, dateadd(day,(abs(CHECKSUM(newid())) % -120) , dateSwitched) as dateCompleted
	from ConfirmedSwitch
)
select *
into #HowManySwitched
from CompletedSwitch
union all 
select *
from notConfirmedSwitch


--How Many switch Cancelled


IF OBJECT_ID('tempdb..#HowManyCancelled') IS NOT NULL 
DROP TABLE #HowManyCancelled
;with CustomerCancel as (
	select  top 20 percent FanID
		,	1 as Cancelled
	from #HowManySwitched
	where switched = 1
), EnergyProvidedCancelled as (
	select   top 10 percent FanID
		,	2 as Cancelled
	from #HowManySwitched
	where switched = 1
	AND fanid not in 
			(	select fanid 
				from CustomerCancel
			)
), notCancelled as (
	select FanID
	,	0 as cancelled
	from #sample
	where FanID NOT IN (
						select FanID
						from CustomerCancel
						union all 
						select FanID
						from EnergyProvidedCancelled
						)
)
select *
into #HowManyCancelled
from CustomerCancel
union all 
select *
from EnergyProvidedCancelled
union all 
select *
from notCancelled

--SwitchType
IF OBJECT_ID('tempdb..#SwitchType') IS NOT NULL 
DROP TABLE #SwitchType
;with SingleSwitch AS (
	select top 80 percent FanID
		, 'Single' as switchType
	from #HowManySwitched
	where switched = 1
), DuelSwitch as (
	select FanID
	, 'duel' as switchType
	from #HowManySwitched
	where switched = 1
	and fanid NOT IN (
						select FanID
						from SingleSwitch
						)

), notSwitched as (
	select FanID
	,	null as switchType
	from #sample
	where FanID NOT IN (
						select FanID
						from SingleSwitch
						union all 
						select FanID
						from DuelSwitch
						)
)
select *
into #SwitchType
from SingleSwitch
Union All 
select *
from DuelSwitch
union all 
select *
from notSwitched



--FuelType - Gas or Eelectricity - SingleFuel only
IF OBJECT_ID('tempdb..#FuelType') IS NOT NULL 
DROP TABLE #FuelType
;with Gas as (
	select top 60 percent FanID
		,	'Gas' as FuelType
	from #SwitchType
	where switchType = 'Single'
), Electricity as (
	select fanid
		,	'Electricity' as FuelType
	from #SwitchType
	where switchType = 'Single'
	AND FanID NOT IN (
						select fanid
						from Gas
					)
), NoFuelType as(
	select FanID
	,	null as fuelType
	from #sample
	where FanID NOT IN (
						select FanID
						from Gas
						union all 
						select FanID
						from Electricity
						)
)
select *
into #FuelType
from Gas
Union All 
select *
from Electricity
union all 
select *
from NoFuelType


--Paidout in rewards
IF OBJECT_ID('tempdb..#CashAmounts') IS NOT NULL 
DROP TABLE #CashAmounts
;with RewardsPayOut as (
	select FanID
	,	ABS(CHECKSUM(NEWID()) % 6) + 1 as payout
	from #HowManySwitched
	where switched = 1
), RewardsRevenue as (
	select	fanid
		,	payout *.25 as revenue
	from RewardsPayOut
), BankPayment as (
	select fanid
		,	revenue * .1 as bankPayment
	from RewardsRevenue
),	CashbackEarned as (
	select fanid
	,	bankPayment *.25 as cashbackEarned
	from BankPayment
)
select s.FanID, rpa.payout , rr.revenue , bp.bankPayment , cashbackEarned
into #CashAmounts
from #sample s
left join RewardsPayOut rpa
on s.FanID = rpa.FanID
left join RewardsRevenue rr
on s.FanID = rr.FanID
left join BankPayment bp
on s.FanID = bp.FanID
left join CashbackEarned ce 
on ce.FanID = s.FanID



select	S.*
	,	coo.clickedOnOffer
	,	hmp.progressed
	,	hms.switched
	,	hms.dateSwitched
	,	hms.dateCompleted
	,	hmc.Cancelled
	,	st.switchType
	,	ft.FuelType 
	,	ca.payout
	,	ca.revenue
	,	ca.bankPayment
	,	ca.cashbackEarned
	,	CASE 
			WHEN s.region = 'Scotland' THEN 'Scotland'
			WHEN s.region = 'Wales' THEN 'Wales'
			ELSE 'England'
		END AS Country
--into #temp
from #sample s
left join #clickedOnOffer coo
on s.FanID = coo.FanID
left join #HowManyProgressed hmp
on s.FanID = hmp.FanID
left join #HowManySwitched hms
on s.FanID = hms.FanID
left join #HowManyCancelled hmc
on s.FanID = hmc.FanID
left join #SwitchType st
on s.FanID = st.FanID
left join #FuelType ft
on s.FanID = ft.FanID
left join #CashAmounts ca
on s.FanID = ca.FanID

END

--drop table #temp

--select fanid,dateSwitched,dateCompleted
--from #temp





