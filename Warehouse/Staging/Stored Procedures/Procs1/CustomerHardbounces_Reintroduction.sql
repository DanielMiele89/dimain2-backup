/*
	Author:		Stuart Barnley

	Date:		January 13th 2016

	Purpose:	Create a process to adjust a customer so that they are not deem Hardbounced 
				unless they bounced subsequantly

	Updates:	NA

*/
CREATE procedure Staging.CustomerHardbounces_Reintroduction (@Date date,@TableName varchar(200))
As

---------------------------------------------------------------------------------------------------
-------------- Add members to the table so they will no longer be marked as hardbounced -----------
---------------------------------------------------------------------------------------------------

Declare @Qry nvarchar(Max)

Set @Qry = '
			Insert into [Staging].[Customer_Hardbounced_Reengaged]
			Select Distinct a.FanID,
					'''+Convert(varchar,@Date, 120)+''' as DateWS,
					'''+Convert(varchar,@Date, 120)+''' as DateEmail
			From '+@TableName+' as a'

Exec sp_ExecuteSQL @Qry
---------------------------------------------------------------------------------------------------
----------------------------------------identify duplicate customer records -----------------------
---------------------------------------------------------------------------------------------------

if object_id('tempdb..#Dups') is not null drop table #Dups
Select Distinct FanID,Min(DateWS) as EarliestEntry
Into #Dups
From [Staging].[Customer_Hardbounced_Reengaged] with (nolock)
Group by FanID
	Having Count(*) > 1

---------------------------------------------------------------------------------------------------
---------------------------------------- Delete ealiest dups --------------------------------------
---------------------------------------------------------------------------------------------------
Delete from [Staging].[Customer_Hardbounced_Reengaged]
from [Staging].[Customer_Hardbounced_Reengaged] as a
inner join #Dups as d
	on	a.FanID = d.FanID and
		a.DateWS = EarliestEntry

Select a.DateWS,Count(*)
From [Staging].[Customer_Hardbounced_Reengaged] as a
Group by a.DateWS
Order by a.DateWS