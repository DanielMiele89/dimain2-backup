/*
Author :	Stuart Barnley
Date:		05th August 2013
Purpose:	RBSG Weekly Reporting - Spend, Earned and Redeeemed
Notes:		Amended to create one table of output to use in SSRS report
			
			23-05-2014 SB - Turned in SP
Run Time:				
*/

Create Procedure Staging.SSRS_R0030_Spend_Earn_Red
				 @WeekStart Date, @WeekEnd Date
as

/*-------------------------------------------------------------------------------
--------------------Set Up Report Parameters-------------------------------------
---------------------------------------------------------------------------------*/
--Set parameters
/*
declare @WeekStart as date   
declare @WeekEnd as date   
set @WeekStart = '03 December 2012'			--Start of Week (Monday)
set @WeekEnd = '09 December 2012'			--End of Week (Sunday)
*/
--create a table to store the date parameter (allows us to execute code in steps)
if object_id('tempdb..#parameter') is not null drop table #parameter
create table  #parameter (ParameterName varchar(20), ParameterDate date)

insert into #parameter values ('WeekStart', @WeekStart)
insert into #parameter values ('WeekEnd', @WeekEnd)

/*-------------------------------------------------------------------------------
--------------------Define the Customer Base For this Report---------------------
---------------------------------------------------------------------------------*/
if object_id('tempdb..#customerbase') is not null drop table #customerbase
select	c.FanID,
		Case
			When r.FanID is null then Cast(c.ActivatedDate as Date)
			Else r.ReportFromDate
		End as ReportFromDate,
		r.AnalysisGroupL1,
		Cast(c.ActivatedDate as DATE) as ActivatedDate
into	#customerbase
from	Relational.Customer c
Left Outer Join Relational.ReportBaseMay2012 r								--Customers in the reporting base defined for May 2012 Retailer Quarterly reports
		on r.FanID = c.FanID
where	(r.IsControl = 0 or c.ActivatedDate >= 'Aug 08, 2013')
--(951051 row(s) affected)


/*-------------------------------------------------------------------------------
--------------------Define the Transactions For this Report---------------------
---------------------------------------------------------------------------------*/
--declare @WeekEnd as date   
--select @WeekEnd = ParameterDate from #parameter where ParameterName  = 'WeekEnd'

if object_id('tempdb..#partnertrans') is not null drop table #partnertrans
select	pt.FanID,
		pt.TransactionAmount,
		pt.AddedDate,
		pt.CashbackEarned,				--This is negative for refund transactions	(as a result of changes in version 31 of DataMart ETL script)
		cast((case when pt.AddedDate >= cb.ActivatedDate then 1 else 0 end) as bit) as HadActivatedByAddedDate,		--Had the customer activated by the time this transaction was added to Reward's database. Condition on added date.
		dateadd(dd, pt.ActivationDays, pt.TransactionDate) as ClearedDate  --This is relative to the transaction date rather than the added date
into	#partnertrans
from	Relational.PartnerTrans pt 
		inner join #customerbase cb on pt.FanID = cb.FanID
where	pt.TransactionDate >= cb.ReportFromDate					--Only include transactions after this specific customer was launched to. This condition is on Transaction Date.
		and	pt.AddedDate <= @WeekEnd	--Only include transactions that were added to the database within the period that we are reporting on. This condition is on Added Date. This is a cumulative report
		and EligibleForCashBack = 1		--Derived in the DataMart using the condition status = 1 and rewardstatus in (0,1). This deliberately excludes transactions for Marketing Suppressed customers which arrived at Reward before the cusotmer had activated.						
/*-------------------------------------------------------------------------------
--------------------Define the Redemptions For this Report----------------------
---------------------------------------------------------------------------------*/
if object_id('tempdb..#redemptions') is not null drop table #redemptions
select  cb.FanID,
		r.ID					as RedeemID,
		t.ID					as TransID,
		cast(t.Date	as date)	as RedemptionDate,
		ri.RedeemType,
		ri.PrivateDescription,
		t.price as RedeemedValue
into	#redemptions	
from	#customerbase cb			--restrict to customers in the customer base								
        inner join slc_report.dbo.Trans t on cb.FanID = t.FanID
        inner join slc_report.dbo.Redeem r on r.id = t.ItemID and t.TypeID=3
        inner join Relational.RedemptionItem ri on r.ID = ri.RedeemID  --Lookup table maintained within Data Management Team
where   not exists (select * from slc_report.dbo.trans where typeid=4 and itemid=t.id)
		and cast(t.Date	as date) <= @WeekEnd

/*-------------------------------------------------------------------------------
--------------------Report Query-------------------------------------------------
---------------------------------------------------------------------------------*/
if object_id('tempdb..#SpendRedem') is not null drop table #SpendRedem
create table #SpendRedem (ReportDay date,SortOrder int, ReportVariable nVarchar(255),ReportValue float) 
declare @ReportDay as date
set @ReportDay = @WeekStart

while @ReportDay <= @WeekEnd
begin
Insert into #SpendRedem
Select * 

from
(		select	@ReportDay as ReportDay,
				1 as SortOrder,
				'Activated - customers earning cashback (cumulative)' as ReportVariable, 
				count(distinct FanID) as ReportValue 
		from	#partnertrans 
		where	HadActivatedByAddedDate = 1 
				and AddedDate <= @ReportDay
		union
		select	@ReportDay as ReportDay,
				2 as SortOrder,
				'Activated - value of cashback cleared (cumulative)' as ReportVariable,		
				sum(CashbackEarned) as ReportValue 
		from	#partnertrans 
		where	HadActivatedByAddedDate = 1 
				and AddedDate <= @ReportDay
				and ClearedDate <= @ReportDay
		union		
		select	@ReportDay as ReportDay,
				3 as SortOrder,
				'Activated - customers with pending cashback (cumulative)' as ReportVariable, 
				count(distinct FanID) as ReportValue 
		from	#partnertrans 
		where	HadActivatedByAddedDate = 1 
				and AddedDate <= @ReportDay
				and ClearedDate > @ReportDay
		union		
		select	@ReportDay as ReportDay,
				4 as SortOrder,
				'Activated - value of cashback pending (cumulative)' as ReportVariable, 
				sum(CashbackEarned) as ReportValue 
		from	#partnertrans 
		where	HadActivatedByAddedDate = 1 
				and AddedDate <= @ReportDay
				and ClearedDate > @ReportDay		
		union
		select	@ReportDay as ReportDay,
				9 as SortOrder,
				'Number of cash redemptions (total- not expressed as £s)' as ReportVariable, 
				count(1) as ReportValue 
		from	#redemptions
		where	RedemptionDate = @ReportDay
				and RedeemType = 'Cash'		
		union
		select	@ReportDay as ReportDay,
				10 as SortOrder,
				'Number of trade-up redemptions (total)' as ReportVariable, 
				count(1) as ReportValue 
		from	#redemptions
		where	RedemptionDate = @ReportDay
				and RedeemType = 'Trade Up'		
		union
		select	@ReportDay as ReportDay,
				11 as SortOrder,
				'Number of charity donations (total)' as ReportVariable, 
				count(1) as ReportValue 
		from	#redemptions
		where	RedemptionDate = @ReportDay
				and RedeemType = 'Charity'
)	as a	
		
set @ReportDay = dateadd(d,1,@ReportDay	)
end	

/*-------------------------------------------------------------------------------
--------------------End of Report Query------------------------------------------
---------------------------------------------------------------------------------*/
select ReportDay,datename(dw,ReportDay) as WeekDay,SortOrder,ReportVariable, ISNULL(ReportValue,0) as ReportValue
		
from #SpendRedem