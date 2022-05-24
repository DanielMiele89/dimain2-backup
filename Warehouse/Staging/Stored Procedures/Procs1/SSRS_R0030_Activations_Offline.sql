/*
Author :	Stuart Barnley
Date:		05 August 2013
Purpose:	Weekly Activations Report to RBSG
Notes:		Amended to be used in Reporting Services Report
*/


Create Procedure Staging.SSRS_R0030_Activations_Offline
				 @WeekStart Date, @WeekEnd Date
as
/*-------------------------------------------------------------------------------
--------------------Set Up Report Parameters-------------------------------------
---------------------------------------------------------------------------------*/
--Set parameters
/*
declare @WeekStart as date   
declare @WeekEnd as date   
set @WeekStart = '03 Dec 2012'			--Start of Week (Monday)
set @WeekEnd = '09 Dec 2012'			--End of Week (Sunday)
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
select	r.FanID,
		c.ActivatedDate,			
		c.ActivatedOffline,
		cast((case when c.ActivatedDate <= @WeekEnd then 1 else 0 end) as bit)	as ActivatedByEndOfWeek  --Had the customer activated by the end of the report week
into	#customerbase
from	Warehouse.Relational.Customer as c
Left Outer join Relational.ReportBaseMay2012 r											--Customers in the reporting base defined for May 2012 Retailer Quarterly reports
		on r.FanID = c.FanID
where   (r.IsControl = 0 or ActivatedDate >= 'Aug 08, 2013')

/*-------------------------------------------------------------------------------
--------------------Report 2 - Activations by Offline / £5 Incentive-------------
---------------------------------------------------------------------------------*/

select	1 as SortOrder, 
		'Total Offline Activations' as ReportVariable, 
		count(1) as Value 
from	#customerbase 
where	ActivatedByEndOfWeek = 1 and ActivatedOffline =1
union
select	2 as SortOrder, 
		'Offline Activations Within Week' as ReportVariable, 
		 count(1) as Value 
from	#customerbase 
where	ActivatedOffline =1 and ActivatedDate between @WeekStart and @WeekEnd