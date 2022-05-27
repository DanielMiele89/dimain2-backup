--Use Warehouse
/*Declare @StartDate Date, @EndDate Date
set @StartDate = 'Aug 01, 2012'
set @EndDate = 'Jan 31, 2014'
Declare @LaunchDate Date
Set @LaunchDate = 'Aug 08, 2013'
*/Create Procedure Staging.RBSG_MonthlyRep_InMonth (@StartDate date, @EndDate date, @LaunchDate date)
as
if object_id('tempdb..#customerbase') is not null drop table #customerbase
select	c.FanID,
		Case
			When r.ReportFromDate is not null then r.ReportFromDate
			Else c.ActivatedDate
		End as ReportFromDate,
		r.AnalysisGroupL1,
		c.ActivatedDate
into	#customerbase
from	Relational.Customer as c
		-----------Link to old Activated Customer base to pull POC non Seeds customers to avoid impact legacy data
		Left Outer join  [InsightArchive].[Customer_ReportBasePOC2_20130724] as IA
			on	c.FanID = ia.Fanid and
				ia.Customer_Type = 'A'
		Left Outer join Relational.ReportBaseMay2012 as r
			on	ia.FanID = r.FanID
where	Activated = 1 and 
		(ActivatedDate >= @LaunchDate or r.Fanid is not null)
		 and	
		(ActivatedDate <= @EndDate or ia.fanid is not null)
--136,223
--Down to here -- 3 Secs
--------------------------------------------------------------------------------------------------------------------------
-------------------------------------Create List of monthly Activations---------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

if object_id('tempdb..#MonthlyActivates') is not null drop table #MonthlyActivates
select cast(datename(month,ActivatedDate) + ' 01, ' + cast(YEAR(ActivatedDate) as varchar(4)) as DATe) as ActivationMonth
,COUNT(FanID) as Activations
Into #MonthlyActivates
from #Customerbase
Group by cast(datename(month,ActivatedDate) + ' 01, ' + cast(YEAR(ActivatedDate) as varchar(4)) as DATe)
Order by ActivationMonth
--Down to here 8 Secs
--Select * from #MonthlyActivates

if object_id('tempdb..#MonthlyActivations_Totals') is not null drop table #MonthlyActivations_Totals
Select ma1.*,SUM(ma2.Activations) as Actionations_to_Date 
Into #MonthlyActivations_Totals
from #MonthlyActivates as ma1
inner join #MonthlyActivates as ma2
	on ma1.ActivationMonth >= ma2.ActivationMonth
Group by ma1.ActivationMonth,ma1.Activations
Order by ma1.ActivationMonth

Drop table #MonthlyActivates
--Down to here seconds
--Select * from #MonthlyActivations_Totals
---------------------------------------------------------------------------------------------------------------------------------
-----------------------Pull off all redemptions----------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------

----if object_id('tempdb..#redemptions') is not null drop table #redemptions
----select  cb.FanID,
----		r.ID					as RedeemID,
----		t.ID					as TransID,
----		cast(t.Date	as date)	as RedemptionDate,
----		ri.RedeemType,
----		ri.PrivateDescription,
----		t.price as RedeemedValue
----into	#redemptions	
----from	#customerbase cb			--restrict to customers in the customer base								
----        inner join SLC_Report.dbo.Trans t on cb.FanID = t.FanID
----        inner join SLC_Report.dbo.Redeem r on r.id = t.ItemID and t.TypeID=3
----        inner join Relational.RedemptionItem ri on r.ID = ri.RedeemID  --Lookup table maintained within Data Management Team
----where   not exists (select * from SLC_Report.dbo.trans where typeid=4 and itemid=t.id)--make sure to remove redemptions that have subsequently been refunded
----		and cast(t.Date	as date) <= @EndDate

if object_id('tempdb..#redemptions') is not null drop table #redemptions
Select	cb.FanID,
		r.TranID,
		Cast(r.RedeemDate as date)	as RedemptionDate,
		r.RedeemType,
		r.RedemptionDescription as PrivateDescription,
		r.CashbackUsed AS RedeemedValue
into	#redemptions
From	#customerbase as cb
inner join Warehouse.Relational.Redemptions as r
	on cb.FanID = r.FanID
Where	Cancelled = 0 and
		cast(r.RedeemDate	as date) <= @EndDate
--- Down to here ??????
-----------------------------------------------------------------------------------------------------------------------------
------------------------------------------Work out redemptions by month since @StartDate-------------------------------------
-----------------------------------------------------------------------------------------------------------------------------		
if object_id('tempdb..#MonthlyRedemptions') is not null drop table #MonthlyRedemptions
select	cast(datename(month,RedemptionDate) + ' 01, ' + cast(YEAR(RedemptionDate) as varchar(4)) as DATe) as RedemptionMonth,
		Sum(Case
				When RedeemType = 'Charity' then 1
				Else 0
			End) CharityCount,
		Cast(Sum(Case
				When RedeemType = 'Charity' then 1
				Else 0
			End) as float) / cast(COUNT(*) as float) as Charity_Pct,
		Sum(Case
				When RedeemType = 'Cash' then 1
				Else 0
			End) CashCount,
		Cast(Sum(Case
				When RedeemType = 'Cash' then 1
				Else 0
			End) as float) / cast(COUNT(*) as float) as Cash_Pct,
		Sum(Case
				When RedeemType = 'Trade Up' then 1
				Else 0
			End) TradeUpCount,
		Cast(Sum(Case
				When RedeemType = 'Trade Up' then 1
				Else 0
			End)as float) / cast(COUNT(*) as float) as TradeUp_Pct,
		COUNT(*) as RedemptionCount,
		SUM(RedeemedValue) as TotalCashbackSpent,
		COUNT(Distinct FanID) as UniqueRedeemers
into #MonthlyRedemptions		
from #redemptions
		Where RedemptionDate Between @StartDate and @EndDate
Group by cast(datename(month,RedemptionDate) + ' 01, ' + cast(YEAR(RedemptionDate) as varchar(4)) as DATe)
Order by RedemptionMonth
-----------------------------------------------------------------------------------------------------------------------------
-------------------------------Add Running Averages to redemptions by month since @StartDate---------------------------------
-----------------------------------------------------------------------------------------------------------------------------		
if object_id('tempdb..#Monthly_Redemptions_RT') is not null drop table #Monthly_Redemptions_RT
select	MR.* ,
		AVG(MR2.CharityCount)		as AVG_CharityCount,
		AVG(MR2.Charity_Pct)		as AVG_Charity_Pct,
		AVG(MR2.CashCount)			as AVG_CashCount,
		AVG(MR2.Cash_Pct)			as AVG_Cash_Pct,
		AVG(MR2.TradeUpCount)		as AVG_TradeUpCount,
		AVG(MR2.TradeUp_Pct)		as AVG_TradeUp_Pct,
		AVG(MR2.RedemptionCount)	as AVG_RedemptionCount,
		AVG(MR2.TotalCashbackSpent) as AVG_TotalCashbackSpent,
		AVG(MR2.UniqueRedeemers)	as AVG_UniqueRedeemers
Into	#Monthly_Redemptions_RT
from #MonthlyRedemptions as MR
inner join #MonthlyRedemptions as MR2
	on MR.RedemptionMonth >= MR2.RedemptionMonth
Group by MR.RedemptionMonth,MR.CharityCount,MR.Charity_Pct,MR.CashCount,MR.Cash_Pct,MR.TradeUpCount,
		 MR.TradeUp_Pct,MR.RedemptionCount,MR.TotalCashbackSpent,MR.UniqueRedeemers
-----------------------------------------------------------------------------------------------------------------
----------------------------Get Cumulative redemption counts (Month by Month)---------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Monthly_Redemptions_Cumulative') is not null drop table #Monthly_Redemptions_Cumulative
Select mr.RedemptionMonth,Count(*) as CumulativeRedemptionCount 
Into #Monthly_Redemptions_Cumulative
from #MonthlyRedemptions as MR
inner join #redemptions as r
	on Dateadd(month,1,mr.RedemptionMonth) > r.RedemptionDate
group by mr.RedemptionMonth


-----------------------------------------------------------------------------------------------------------------
----------------------------Pull off transactions since launch---------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#partnertrans') is not null drop table #partnertrans
select	pt.FanID,
		pt.PartnerID,
		pt.TransactionAmount,
		pt.AddedDate,
		pt.CashbackEarned,				
		cast((case when pt.AddedDate >= cb.ActivatedDate then 1 else 0 end) as bit) as HadActivatedByAddedDate		--Had the customer activated by the time this transaction was added to Reward's database. Condition on added date.
into	#partnertrans
from	warehouse.Relational.PartnerTrans pt 
		inner join #customerbase cb on pt.FanID = cb.FanID
where	pt.TransactionDate >= cb.ReportFromDate					--Only include transactions after this specific customer was launched to. This condition is on Transaction Date.
		and	pt.AddedDate <= @EndDate		--Only include transactions that were added to the database within the period that we are reporting on. This condition is on Added Date.
		and EligibleForCashBack = 1			--Only include transactions eligible for cashback
-------------------------------------------------------------------------------------------------------------------------------
-----------------------------------Total Spent and Earned per Month-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Trans_Counts') is not null drop table #Trans_Counts		
select	cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE) as TranAddedMonth,
		sum(TransactionAmount)					as Spend,
		sum(CashbackEarned)						as CashbackEarned,
		count(distinct pt.FanID)				as CountMembersSpent,
		Sum(Case
				When t.Partner_Tier_Level = 1 then TransactionAmount 
				Else 0
			End) as SpendTier1,
		Sum(Case
				When t.Partner_Tier_Level = 1 then TransactionAmount 
				Else 0
			End)/sum(TransactionAmount)		as SpendTier1Pct,	
		Sum(Case
				When t.Partner_Tier_Level = 2 then TransactionAmount 
				Else 0
			End) as SpendTier2,
		Sum(Case
				When t.Partner_Tier_Level = 2 then TransactionAmount 
				Else 0
			End)/sum(TransactionAmount)		as SpendTier2Pct,	
		Sum(Case
				When t.Partner_Tier_Level = 3 then TransactionAmount 
				Else 0
			End) as SpendTier3,
		Sum(Case
				When t.Partner_Tier_Level = 3 then TransactionAmount 
				Else 0
			End)/sum(TransactionAmount)		as SpendTier3Pct						
into #Trans_Counts
from #partnertrans as pt
left outer join warehouse.relational.Partner_Tier as t
	on pt.PartnerID = t.PartnerID

Where	AddedDate Between @StartDate and @EndDate
Group By cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE)

--Select Tc.* from #Trans_Counts as TC
-----------------------------------------------------------------------------------------------------------------------------
-------------------------------Add Running Averages to Total Spent and Earned per Month--------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#SpendEarn_RT') is not null drop table #SpendEarn_RT
Select	Tc.*,
		AVG(TC2.Spend)				as Avg_Spend,
		AVG(tc2.CashbackEarned)		as Avg_CashbackEarned,
		AVG(tc2.CountMembersSpent)	as Avg_Count_Membes_Spent,
		AVG(tc2.SpendTier1)			as avg_SpendTier1,
		AVG(tc2.SpendTier2)			as avg_SpendTier2,
		AVG(tc2.SpendTier3)			as avg_SpendTier3
into	#SpendEarn_RT		
from #Trans_Counts as TC
inner join #Trans_Counts as tc2
	on tc.TranAddedMonth >= tc2.TranAddedMonth
group by tc.TranAddedMonth,tc.Spend,tc.CashbackEarned,tc.CountMembersSpent,tc.SpendTier1,
		 tc.SpendTier1Pct,tc.SpendTier2,tc.SpendTier2Pct,tc.SpendTier3,tc.SpendTier3Pct
---?????? 1:27
-------------------------------------------------------------------------------------------------------------------------------
----------------------------------Pull amount of cashback earned per customer per month----------------------------------------
-------------------------------------------------------------------------------------------------------------------------------

if object_id('tempdb..#Mth_Cb_Earned') is not null drop table #Mth_Cb_Earned
Select	cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE) as TranAddedMonth,
		Fanid,
		SUM(CashbackEarned) as Monthly_CB_Earned
Into	#Mth_Cb_Earned
from	#partnertrans
Where	AddedDate <= @EndDate
group by FanID,cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE)

-------------------------------------------------------------------------------------------------------------------------------
-------------------------------Create running total for monthly cashback earned per customer-----------------------------------
-------------------------------------------------------------------------------------------------------------------------------

if object_id('tempdb..#Mth_Cb_Earned_RunTot') is not null drop table #Mth_Cb_Earned_RunTot
Select	m1.*,
		Sum(m2.Monthly_CB_Earned) as CB_Earned_RunTot, 
		Case
			When Sum(m2.Monthly_CB_Earned) > 15 then 1
			Else 0
		End as CB_GBP15Plus
into #Mth_CB_Earned_RunTot
from #Mth_Cb_Earned as m1
inner join #Mth_Cb_Earned as m2
	on m1.FanID = m2.FanID and m1.TranAddedMonth >= m2.TranAddedMonth
Group by m1.FanID,m1.TranAddedMonth,m1.Monthly_CB_Earned
Order by m1.Fanid,m1.TranaddedMonth
-------------------------------------------------------------------------------------------------------------------------------
---------------------Link each month to latest month cashback earned to know running total per month---------------------------
-------------------------------------------------------------------------------------------------------------------------------
/*This is needed as not every month has cashback earning and also peoples running running total can go down as well 
as up based on refunds*/

if object_id('tempdb..#MonthlyLinking') is not null drop table #MonthlyLinking
Select	tc.TranAddedMonth,
		rt.fanid,
		MAX(rt.TranAddedMonth) as latestDate
into #MonthlyLinking
from #Trans_Counts as tc
inner join #Mth_CB_Earned_RunTot as rt
	on tc.TranAddedMonth >= rt.TranAddedMonth and tc.TranAddedMonth < @EndDate-- AND
Group by tc.TranAddedMonth,rt.FanID
-------------------------------------------------------------------------------------------------------------------------------
--------------------------Count number of customer per month that had over 15 pounds cashback-----------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--This does mean the odd person will go into to one months count only to come back out

if object_id('tempdb..#GBP15Plus') is not null drop table #GBP15Plus
select ml.TranAddedMonth,SUM(rt.CB_GBP15Plus) as CB_GBP15Plus_Customers 
into	#GBP15Plus
from #MonthlyLinking as ml
	inner join #Mth_CB_Earned_RunTot as rt
		on	ml.FanID = rt.FanID and
			ml.latestDate = rt.TranAddedMonth
Group by ml.TranAddedMonth 

-------------------------------------------------------------------------------------------------------------------------------
-----------------------------------Add test amount of activations to check use-------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
--Insert into #MonthlyActivations_Totals
--select ActivationMonth = Cast('Dec 01, 2012' as DATE),2 as Activations,80763 as Activations_to_date

-------------------------------------------------------------------------------------------------------------------------------
------------------------------------------Produce Activation table-------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#MonthlyActivations') is not null drop table #MonthlyActivations
Select tc.TranAddedMonth,max(act.Actionations_to_Date) Activations
into #MonthlyActivations
from #Trans_Counts as tc
inner join #MonthlyActivations_Totals as Act
	on tc.TranAddedMonth >= Act.ActivationMonth
Group by tc.TranAddedMonth
---??????? 3:22
--------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------Partner Group table	--------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PartnerGrouping') is not null drop table #PartnerGrouping
select P.PartnerID,P.PartnerName,Case when g.PartnerID IS null then PartnerName Else PartnerGroupName End as PartnerNameGroup
Into #PartnerGrouping
from warehouse.relational.Partner as p
Left Outer Join warehouse.staging.PartnerGroups as g
	on p.PartnerID = g.PartnerID and PartnerGroupID <> 0 and g.UseForReport = 1
Order by PartnerNameGroup
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#SpendByPartner_Ranked') is not null drop table #SpendByPartner_Ranked
Select	ROW_NUMBER() OVER(PARTITION BY TranAddedMonth ORDER BY Spend DESC) AS Row,
		TranAddedMonth,
		Spend,
		PartnerNameGroup
into	#SpendByPartner_Ranked
from
(select
cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE) as TranAddedMonth,
		sum(TransactionAmount)					as Spend,
		PartnerNameGroup
From #partnertrans as pt
inner join #PartnerGrouping as pg
	on pt.PartnerID = pg.PartnerID
Where AddedDate >= @StartDate
group by 
cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE),
		PartnerNameGroup
) as a
--Select * from #SpendByPartner_Ranked
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#SpendTop5Partners') is not null drop table #SpendTop5Partners
Select	TranAddedMonth,
		Max(Case
				When [ROW] = 1 then PartnerNameGroup
				Else ''
			End) as PartnerName1,
		Sum(Case
				When [ROW] = 1 then Spend
				Else 0
			End) as Spend1,
		Max(Case
				When [ROW] = 2 then PartnerNameGroup
				Else ''
			End) as PartnerName2,
		Sum(Case
				When [ROW] = 2 then Spend
				Else	 0
			End) as Spend2,
		Max(Case
				When [ROW] = 3 then PartnerNameGroup
				Else ''
			End) as PartnerName3,
		Sum(Case
				When [ROW] = 3 then Spend
				Else 0
			End) as Spend3,
		Max(Case
				When [ROW] = 4 then PartnerNameGroup
				Else ''
			End) as PartnerName4,
		Sum(Case
				When [ROW] = 4 then Spend
				Else 0
			End) as Spend4,
		Max(Case
				When [ROW] = 5 then PartnerNameGroup
				Else ''
			End) as PartnerName5,
		Sum(Case
				When [ROW] = 5 then Spend
				Else 0
			End) as Spend5
into	#SpendTop5Partners
From	#SpendByPartner_Ranked
Group by TranAddedMonth		
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#PartnerSpend') is not null drop table #PartnerSpend
select	pg.PartnerNameGroup, 
		cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE) as TranAddedMonth,
		Sum(pt.TransactionAmount) as tranamount
Into #PartnerSpend
from #partnertrans as pt
inner join #PartnerGrouping as pg
	on pt.PartnerID = pg.PartnerID
Where AddedDate >= @StartDate
Group by pg.PartnerNameGroup, 
		cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE)

if object_id('tempdb..#CumulativeSpend') is not null drop table #CumulativeSpend
Select TranAddedMonth,
		Max(Case
				When [ROW] = 1 then PartnerNameGroup
				Else ''
			End) as PartnerName1_Cum,
		Sum(Case
				When [ROW] = 1 then rollingspend
				Else 0
			End) as Spend1_Cum,
		Max(Case
				When [ROW] = 2 then PartnerNameGroup
				Else ''
			End) as PartnerName2_Cum,
		Sum(Case
				When [ROW] = 2 then rollingspend
				Else	 0
			End) as Spend2_Cum,
		Max(Case
				When [ROW] = 3 then PartnerNameGroup
				Else ''
			End) as PartnerName3_Cum,
		Sum(Case
				When [ROW] = 3 then rollingspend
				Else 0
			End) as Spend3_Cum,
		Max(Case
				When [ROW] = 4 then PartnerNameGroup
				Else ''
			End) as PartnerName4_Cum,
		Sum(Case
				When [ROW] = 4 then rollingspend
				Else 0
			End) as Spend4_Cum,
		Max(Case
				When [ROW] = 5 then PartnerNameGroup
				Else ''
			End) as PartnerName5_Cum,
		Sum(Case
				When [ROW] = 5 then rollingspend
				Else 0
			End) as Spend5_Cum
into	#CumulativeSpend
from
(Select a.*,ROW_NUMBER() OVER(PARTITION BY TranAddedMonth ORDER BY RollingSpend DESC) AS [Row]
from
(Select a.*,Sum(ps.tranamount) as rollingspend from 
(select distinct TranAddedMonth,pg.PartnerNameGroup from #Trans_Counts as tc
,#PartnerGrouping as pg) as a
Inner join #PartnerSpend as PS
	on a.PartnerNameGroup = ps.PartnerNameGroup and a.TranAddedMonth >= ps.TranAddedMonth
Group by a.PartnerNameGroup,a.TranAddedMonth
--Order by a.PartnerNameGroup,a.TranAddedMonth
) as a
) as a
Group by TranAddedMonth
-------------------------------------------------------------------------------------------
-------------------What is 20% and 40% of Activated base-----------------------------------
-------------------------------------------------------------------------------------------
if object_id('tempdb..#Activations_Pct') is not null drop table #Activations_Pct
Select *,round(Activations*0.20,0) as TwentyPct,round(Activations*0.40,0) as FortyPct
into #Activations_Pct
from #MonthlyActivations

-------------------------------------------------------------------------------------------
----------------------------------In Month spend-------------------------------------------
-------------------------------------------------------------------------------------------		
--declare @StartDate date
--set @StartDate = 'Aug 01, 2012'
if object_id('tempdb..#Cust_MonthlySpend') is not null drop table #Cust_MonthlySpend
Select cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE) as TranAddedMonth,
		FanID,
		SUM(TransactionAmount) as MonthlySpend,
		COUNT(*) as TranCount,
		SUM(CashBackEarned) as MonthlyEarned
Into #Cust_MonthlySpend
from #partnertrans
Where AddedDate >= @StartDate
Group by cast(datename(month,AddedDate) + ' 01, ' + cast(YEAR(AddedDate) as varchar(4)) as DATE),
		FanID
-------------------------------------------------------------------------------------------
------------------------Cumualtive spend------------------------------------
-------------------------------------------------------------------------------------------		
--declare @StartDate date
--set @StartDate = 'Aug 01, 2012'
if object_id('tempdb..#Cust_Cum_Spend') is not null drop table #Cust_Cum_Spend
select Ml.TranAddedMonth,FanID,SUM(TransactionAmount) as TotalSpend 
Into #Cust_Cum_Spend
from #PartnerTrans as PT
inner join (select Distinct TranAddedMonth from #MonthlyLinking) as ML
	on pt.AddedDate < DateAdd(month,1,ML.TranAddedMonth)
Where AddedDate >=@StartDate
group by  Ml.TranAddedMonth,FanID
Order by FanID,TranAddedMonth
-------------------------------------------------------------------------------------------
------------------------Ascertain top 20% and 40% spend------------------------------------
-------------------------------------------------------------------------------------------
if object_id('tempdb..#Spend_Pct') is not null drop table #Spend_Pct
Select	Act.*,
		Sum(Case
				When a.RowNo <= Act.TwentyPct then A.MonthlySpend
				Else 0
			End) as MonthlySpend_20Pct,
		Sum(Case
				When a.RowNo <= Act.TwentyPct then A.MonthlyEarned
				Else 0
			End) as MonthlyEarned_20Pct,
		Sum(Case
				When a.RowNo <= Act.TwentyPct then A.TranCount
				Else 0
			End) as MonthlyTrans_20Pct,
		SUM(A.MonthlySpend) as MonthlySpend_40Pct,
		SUM(A.MonthlyEarned) as MonthlyEarned_40Pct,
		SUM(A.TranCount) as MonthlyTrans_40Pct
into #Spend_Pct
from #Activations_Pct as Act
inner join 
(Select c.FanID,c.TranAddedMonth,c.TotalSpend,m.MonthlySpend,m.TranCount,m.MonthlyEarned,ROW_NUMBER() over (partition by c.TranAddedMonth order by c.TotalSpend desc) as RowNo
from #Cust_Cum_Spend as c
Left Outer join #Cust_MonthlySpend as m
	on	c.TranAddedMonth = m.TranAddedMonth and
		c.FanID = m.FanID
) as a
	on Act.TranAddedMonth = a.TranAddedMonth and
	   a.RowNo <= Act.FortyPct
Group by Act.TranAddedMonth,Act.Activations,Act.TwentyPct,Act.FortyPct
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------

if object_id('tempdb..#Spend_Pct_Avg') is not null drop table #Spend_Pct_Avg
Select	sp1.*,
		avg(sp2.MonthlySpend_20Pct) as Avg_MS_20Pct,
		avg(sp2.MonthlyEarned_20Pct) as Avg_ME_20Pct,
		avg(sp2.MonthlyTrans_20Pct) as Avg_MT_20Pct,
		avg(sp2.MonthlySpend_40Pct) as Avg_MS_40Pct,
		avg(sp2.MonthlyEarned_40Pct) as Avg_ME_40Pct,
		avg(sp2.MonthlyTrans_40Pct) as Avg_MT_40Pct
into #Spend_Pct_Avg
from #Spend_Pct as sp1
inner join #Spend_Pct as sp2
	on sp1.TranAddedMonth >= sp2.TranAddedMonth
Group By sp1.TranAddedMonth,sp1.Activations,sp1.FortyPct,sp1.TwentyPct,sp1.MonthlySpend_20Pct,sp1.MonthlyEarned_20Pct,sp1.MonthlyTrans_20Pct,sp1.MonthlySpend_40Pct,sp1.MonthlyEarned_40Pct,sp1.MonthlyTrans_40Pct
	

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('tempdb..#FinalData') is not null drop table #FinalData
select a.* ,MRC.CumulativeRedemptionCount,b.*,c.CB_GBP15Plus_Customers,
		Case
			When a.RedemptionMonth < 'Aug 01, 2013' then 80761
			Else d.Activations
		End as Activations,e.PartnerName1,e.Spend1,e.PartnerName2,e.Spend2,e.PartnerName3,e.Spend3,e.PartnerName4,e.Spend4, e.PartnerName5,e.Spend5,cs.PartnerName1_Cum,cs.Spend1_Cum,cs.PartnerName2_Cum,cs.Spend2_Cum,cs.PartnerName3_Cum,cs.Spend3_Cum,
		cs.PartnerName4_Cum,cs.Spend4_Cum, cs.PartnerName5_Cum,cs.Spend5_Cum,
		s.MonthlySpend_20Pct,s.MonthlyTrans_20Pct,s.MonthlyEarned_20Pct,s.MonthlySpend_40Pct,s.MonthlyTrans_40Pct,s.MonthlyEarned_40Pct,s.Avg_MS_20Pct,s.Avg_ME_20Pct,s.Avg_MT_20Pct,s.Avg_MS_40Pct,s.Avg_ME_40Pct,
		s.Avg_MT_40Pct,
		Case
			When a.RedemptionMonth = Dateadd(Month,-1,Dateadd(day,1,@EndDate)) then 'TM'
			When a.RedemptionMonth = Dateadd(Month,-2,Dateadd(day,1,@EndDate)) then 'LM'
			Else 'O'
		End as WhichMonth
Into #FinalData
from #Monthly_Redemptions_RT as a
inner join #SpendEarn_RT as b
	on a.RedemptionMonth = b.TranAddedMonth
inner join #Monthly_Redemptions_Cumulative as MRC
	on a.RedemptionMonth = MRC.RedemptionMonth
inner join #GBP15Plus as c
	on a.RedemptionMonth = c.TranAddedMonth
inner join #MonthlyActivations as d
	on a.RedemptionMonth = d.TranAddedMonth
inner join #SpendTop5Partners as e
	on a.RedemptionMonth = e.TranAddedMonth
inner join #CumulativeSpend as cs
	on a.RedemptionMonth = cs.TranAddedMonth
inner join #Spend_Pct_Avg as s
	on a.RedemptionMonth = s.TranAddedMonth
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
if object_id('Warehouse.staging.RBSG_MonthlyReport_InMonth') is not null drop table Warehouse.staging.RBSG_MonthlyReport_InMonth
Select fd1.*,Cast(Sum(fd2.Activations) as real)/Count(fd2.RedemptionMonth)  as AverageActivations
Into Warehouse.staging.RBSG_MonthlyReport_InMonth
from #FinalData as fd1
inner join #FinalData as fd2
	on fd2.redemptionMonth <= fd1.RedemptionMonth
Group by fd1.RedemptionMonth,fd1.CharityCount,fd1.Charity_Pct,fd1.CashCount,fd1.Cash_Pct,fd1.TradeUpCount,fd1.TradeUp_Pct,
		fd1.RedemptionCount,fd1.TotalCashbackSpent,fd1.UniqueRedeemers,fd1.AVG_CharityCount,fd1.AVG_Charity_Pct,fd1.AVG_CashCount,
		fd1.AVG_Cash_Pct,fd1.AVG_TradeUpCount,fd1.AVG_TradeUp_Pct,fd1.AVG_RedemptionCount,fd1.AVG_TotalCashbackSpent,fd1.AVG_UniqueRedeemers,
		fd1.CumulativeRedemptionCount,fd1.TranAddedMonth,fd1.Spend,fd1.CashbackEarned,fd1.CountMembersSpent,fd1.SpendTier1,fd1.SpendTier1Pct,
		fd1.SpendTier2,fd1.SpendTier2Pct,fd1.SpendTier3,fd1.SpendTier3Pct,fd1.Avg_Spend,fd1.Avg_CashbackEarned,fd1.Avg_Count_Membes_Spent,
		fd1.avg_SpendTier1,fd1.avg_SpendTier2,fd1.avg_SpendTier3,fd1.CB_GBP15Plus_Customers,fd1.Activations,fd1.PartnerName1,fd1.Spend1,
		fd1.PartnerName2,fd1.Spend2,fd1.PartnerName3,fd1.Spend3,fd1.PartnerName4,fd1.Spend4,fd1.PartnerName5,fd1.Spend5,fd1.PartnerName1_Cum,
		fd1.Spend1_Cum,fd1.PartnerName2_Cum,fd1.Spend2_Cum,fd1.PartnerName3_Cum,fd1.Spend3_Cum,fd1.PartnerName4_Cum,fd1.Spend4_Cum,
		fd1.PartnerName5_Cum,fd1.Spend5_Cum,fd1.MonthlySpend_20Pct,fd1.MonthlyTrans_20Pct,fd1.MonthlyEarned_20Pct,fd1.MonthlySpend_40Pct,
		fd1.MonthlyTrans_40Pct,fd1.MonthlyEarned_40Pct,fd1.Avg_MS_20Pct,fd1.Avg_ME_20Pct,fd1.Avg_MT_20Pct,fd1.Avg_MS_40Pct,fd1.Avg_ME_40Pct,
		fd1.Avg_MT_40Pct,fd1.WhichMonth