/*
		Author:				Stuart Barnley

		Date:				28th October 2015

		Purpose:			Provide Reward balances for Currently Active MyReward Customers

*/

CREATE Procedure Staging.SSRS_R0106_Balances_CurrentlyActive
As
--------------------------------------------------------------------------------------------------
----------------------------------Create Groupings to split Balances by---------------------------
--------------------------------------------------------------------------------------------------
if object_id('tempdb..#BalanceGroupings') is not null drop table #BalanceGroupings
Select *
Into #BalanceGroupings
From
(
Select 1 as ID, '£0.01 - £4.99' as [Grouping] Union All
Select 2 as ID, '£5.00 - £9.99' as [Grouping] Union All
Select 3 as ID, '£10.00 - £14.99' as [Grouping] Union All
Select 4 as ID, '£15.00 - £19.99' as [Grouping] Union All
Select 5 as ID, '£20.00 - £24.99' as [Grouping] Union All
Select 6 as ID, '£25.00 - £29.99' as [Grouping] Union All
Select 7 as ID, '£30.00 - £34.99' as [Grouping] Union All
Select 8 as ID, '£35.00 - £39.99' as [Grouping] Union All
Select 9 as ID, '£40.00 - £44.99' as [Grouping] Union All
Select 10 as ID, '£45.00 - £49.99' as [Grouping] Union All
Select 11 as ID, '£50.00+' as [Grouping] Union All
Select 0 as ID, 'Less Than £0.01' as [Grouping]
) as a

--------------------------------------------------------------------------------------------------
-------------------------------Find Rewards based on Available Balances---------------------------
--------------------------------------------------------------------------------------------------
if object_id('tempdb..#CCA') is not null drop table #CCA
Select 	Case
			When ClubCashAvailable Between 0.01 and 4.99 then 1
			When ClubCashAvailable Between 5 and 9.99 then 2
			When ClubCashAvailable Between 10 and 14.99 then 3
			When ClubCashAvailable Between 15 and 19.99 then 4
			When ClubCashAvailable Between 20 and 24.99 then 5
			When ClubCashAvailable Between 25 and 29.99 then 6
			When ClubCashAvailable Between 30 and 34.99 then 7
			When ClubCashAvailable Between 35 and 39.99 then 8
			When ClubCashAvailable Between 40 and 44.99 then 9
			When ClubCashAvailable Between 45 and 49.99 then 10
			When ClubCashAvailable >= 50 then 11
			Else 0
		End as Balances,
		Count(*) as Customers,
		Sum(ClubCashAvailable) as ClubCashAvailable
Into #CCA
from Relational.Customer as c
inner join slc_report.dbo.fan as f
	on c.FanID = f.id
Where c.CurrentlyActive = 1
Group By 
		Case
			When ClubCashAvailable Between 0.01 and 4.99 then 1
			When ClubCashAvailable Between 5 and 9.99 then 2
			When ClubCashAvailable Between 10 and 14.99 then 3
			When ClubCashAvailable Between 15 and 19.99 then 4
			When ClubCashAvailable Between 20 and 24.99 then 5
			When ClubCashAvailable Between 25 and 29.99 then 6
			When ClubCashAvailable Between 30 and 34.99 then 7
			When ClubCashAvailable Between 35 and 39.99 then 8
			When ClubCashAvailable Between 40 and 44.99 then 9
			When ClubCashAvailable Between 45 and 49.99 then 10
			When ClubCashAvailable >= 50 then 11
			Else 0
		End

--------------------------------------------------------------------------------------------------
--------------------------Find Rewards based on Available+Pending Balances------------------------
--------------------------------------------------------------------------------------------------
if object_id('tempdb..#CCP') is not null drop table #CCP
Select 	Case
			When ClubCashPending Between 0.01 and 4.99 then 1
			When ClubCashPending Between 5 and 9.99 then 2
			When ClubCashPending Between 10 and 14.99 then 3
			When ClubCashPending Between 15 and 19.99 then 4
			When ClubCashPending Between 20 and 24.99 then 5
			When ClubCashPending Between 25 and 29.99 then 6
			When ClubCashPending Between 30 and 34.99 then 7
			When ClubCashPending Between 35 and 39.99 then 8
			When ClubCashPending Between 40 and 44.99 then 9
			When ClubCashPending Between 45 and 49.99 then 10
			When ClubCashPending >= 50 then 11
			Else 0
		End as Balances,
		Count(*) as Customers,
		Sum(ClubCashPending) as ClubCashPending
Into #CCP
from Relational.Customer as c
inner join slc_report.dbo.fan as f
	on c.FanID = f.id
Where c.CurrentlyActive = 1
Group By 
		Case
			When ClubCashPending Between 0.01 and 4.99 then 1
			When ClubCashPending Between 5 and 9.99 then 2
			When ClubCashPending Between 10 and 14.99 then 3
			When ClubCashPending Between 15 and 19.99 then 4
			When ClubCashPending Between 20 and 24.99 then 5
			When ClubCashPending Between 25 and 29.99 then 6
			When ClubCashPending Between 30 and 34.99 then 7
			When ClubCashPending Between 35 and 39.99 then 8
			When ClubCashPending Between 40 and 44.99 then 9
			When ClubCashPending Between 45 and 49.99 then 10
			When ClubCashPending >= 50 then 11
			Else 0
		End
--------------------------------------------------------------------------------------------------
--------------------------Find Rewards based on Available+Pending Balances------------------------
--------------------------------------------------------------------------------------------------

Select	a.ID,
		a.[Grouping],
		Coalesce(cca.Customers,0) as Customers_Av,
		Coalesce(cca.ClubCashAvailable,0) ClubCashAvailable,
		Coalesce(ccp.Customers,0) as Customer_Pen,
		Coalesce(ccp.ClubCashPending,0) as ClubCashPending
From #BalanceGroupings as a
Left Outer join #CCA as cca
	on a.ID = cca.Balances
Left Outer join #CCP as ccp
	on a.ID = ccp.Balances



	--Select * from #CCA