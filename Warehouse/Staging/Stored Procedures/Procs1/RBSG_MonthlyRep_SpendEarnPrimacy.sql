/*
Author:		Stuart Barnley
Date:		28 August 2013
Purpose:	Report Spend and Earned for RBS.
Notes:		Completely re-written 27 July to align with agreed definitions
			implemented when reporting migrated from IT to Data Management.	
			
			Transactions are assessed based on whether the customer had activated at the time that it
			was added to our system.
			
			The ouput of this report is used to populate the RBSG Monthly Report, "Spend and Earn" tab:
			
			Activated I5:082
			Non Activated A5:G85
			
			NB. The number of rows of output is variable for this report.
			
			Amended to new database name
						
*/



Create Procedure Staging.RBSG_MonthlyRep_SpendEarnPrimacy (@StartDate date, @EndDate date,@LaunchDate date)
as
/*-------------------------------------------------------------------------------
--------------------Set Up Report Parameters-------------------------------------
---------------------------------------------------------------------------------*/
--Set parameters
declare @ReportStart as date   
set @ReportStart = DATEADD(MONTH,-1,dateadd(day,1,@EndDate))			--Start of Week (Monday)

--create a table to store the date parameter (allows us to execute code in steps)
if object_id('tempdb..#parameter') is not null drop table #parameter
create table  #parameter (ParameterName varchar(20), ParameterDate date)

insert into #parameter values ('ReportStart', @ReportStart)
insert into #parameter values ('ReportEnd', @EndDate)

--select ParameterDate from #parameter where ParameterName  = 'ReportStart'
--select ParameterDate from #parameter where ParameterName  = 'ReportEnd'

/*-------------------------------------------------------------------------------
--------------------Define the Customer Base For this Report---------------------
---------------------------------------------------------------------------------*/
if object_id('tempdb..#customerbase') is not null drop table #customerbase
select	c.FanID,
		Case
			When r.ReportFromDate is not null then r.ReportFromDate
			Else c.ActivatedDate
		End as ReportFromDate,
		Case
			When C.Primacy is null then 'U' 
			Else c.Primacy
		End as Primacy,
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
		ActivatedDate < @EndDate

/*-------------------------------------------------------------------------------
--------------------Define the Transactions For this Report---------------------
---------------------------------------------------------------------------------*/

if object_id('tempdb..#partnertrans') is not null drop table #partnertrans
select	pt.FanID,
		cb.Primacy,
		pt.PartnerID,
		pt.TransactionAmount,
		pt.AddedDate,
		pt.CashbackEarned,				--This is negative for refund transactions	(as a result of changes in version 31 of DataMart ETL script)
		cast((case when pt.AddedDate >= cb.ActivatedDate then 1 else 0 end) as bit) as HadActivatedByAddedDate,					--Had the customer activated by the time this transaction was added to Reward's database. Condition on added date.
		case when dateadd(dd, pt.ActivationDays, cast(pt.TransactionDate as date)) <= @EndDate then 1 else 0 end as HadClearedByEndOfMonth  --This is relative to the transaction date rather than the added date
into	#partnertrans
from	warehouse.Relational.PartnerTrans pt 
		inner join #customerbase cb on pt.FanID = cb.FanID
where	pt.TransactionDate >= cb.ReportFromDate					--Only include transactions after this specific customer was launched to. This condition is on Transaction Date.
		and	pt.AddedDate between @ReportStart and @EndDate	--Only include transactions that were added to the database within the period that we are reporting on. This condition is on Added Date. This report is NOT cumulative.
		and EligibleForCashBack = 1		--Derived in the DataMart using the condition status = 1 and rewardstatus in (0,1). This deliberately excludes transactions for Marketing Suppressed customers which arrived at Reward before the cusotmer had activated.						

--Separate cleared and pending cashback
alter table #partnertrans add PendingCashback money
alter table #partnertrans add ClearedCashback money
--go

update	#partnertrans
set		ClearedCashback = CashbackEarned * cast(HadClearedByEndOfMonth  as tinyint),		--1 if the cashback had cleared
		PendingCashback = CashbackEarned * (1-cast(HadClearedByEndOfMonth  as tinyint))		--0 if the cashback had cleared, 1 if not
		

		--Select * from #PartnerTrans
/*-------------------------------------------------------------------------------
--------------------Report Query-------------------------------------------------
---------------------------------------------------------------------------------*/
if object_id('Warehouse.staging.RBSG_MonthlyReport_SpendEarnPrimacy') is not null drop table Warehouse.staging.RBSG_MonthlyReport_SpendEarnPrimacy
select 
	   --pt.HadActivatedByAddedDate,
	   --p.PartnerName,
	   pt.Primacy,
	   count(distinct FanID)							as UniqueCustomerCount,
	   sum(TransactionAmount)							as TransactionAmount,
	   sum(ClearedCashBack)+sum(PendingCashback)		as TotalCashBack,
	   sum(ClearedCashBack)								as ClearedCashBack,
	   sum(PendingCashback)								as PendingCashback
Into Warehouse.staging.RBSG_MonthlyReport_SpendEarnPrimacy
from   #partnertrans pt 
		inner join warehouse.Relational.Partner p on pt.PartnerID = p.PartnerID
group by pt.Primacy--,pt.HadActivatedByAddedDate, p.PartnerName
Order by /*pt.HadActivatedByAddedDate,p.PartnerName,*/pt.Primacy