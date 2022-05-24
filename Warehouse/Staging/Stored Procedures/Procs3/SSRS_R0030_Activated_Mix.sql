/*
Author :	Stuart Barnley
Date:		05 August 2013
Purpose:	Weekly Activations Report to RBSG
Notes:		Amended to be used in Reporting Services Report

			23-05-2014 SB - Turned into Stored Procedure 
*/

Create Procedure Staging.SSRS_R0030_Activated_Mix
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
--declare @WeekEnd as date   
--select @WeekEnd = ParameterDate from #parameter where ParameterName  = 'WeekEnd'

if object_id('tempdb..#customerbase') is not null drop table #customerbase
select	r.FanID,
		c.ActivatedDate,			
		c.ActivatedOffline,
		cast((case when c.ActivatedDate <= @WeekEnd then 1 else 0 end) as bit)	as ActivatedByEndOfWeek  --Had the customer activated by the end of the report week
into	#customerbase
from	Relational.Customer c 
Left Outer Join Relational.ReportBaseMay2012 r											--Customers in the reporting base defined for May 2012 Retailer Quarterly reports
		on c.FanID = r.FanID
where (r.IsControl = 0 or c.ActivatedDate >= 'Aug 08, 2013')

/*-------------------------------------------------------------------------------
--------------------Report 1 - Activations by Invitation Media-------------------
---------------------------------------------------------------------------------*/

select	sum(case when ActivatedDate between @WeekStart and @WeekEnd then 1 else 0 end)		as ActivationsInWeek,
		sum(case when ActivatedByEndOfWeek = 1 then 1 else 0 end)							as TotalActivations,
		cast(sum(case when ActivatedByEndOfWeek=1 then 1 else 0 end) as real)/cast(sum(1)as real)		as PercentActivated
from    #customerbase cb