
CREATE Procedure [Staging].[SLC_Report_DailySFDLoad_RetroRun]
As

Exec [Staging].[CBP_DailyProductWelcomeDataForSFD_RetroRun]

Select a.FanID,c.email, a.WelcomeCode from Warehouse.Staging.FanSFDDailyUploadData_RetroRun as a
inner join warehouse.relational.Customer as c
	on a.fanid = c.fanid
Where c.currentlyActive = 1 and EmailStructureValid = 1 and hardbounced = 0

Exec [Staging].[SLC_Report_DailyLoad_FirstSpend_RetroRun]

Select	a.FanID as [Customer ID],
		c.Email,
		a.[Date] as FirstEarndate,
		a.FirstEarnType,
		a.FirstEarnValue,
		a.*
from Staging.Customers_Passed0GBP_RetroRun as a
inner join relational.customer as c
	on a.FanID = c.FanID
Where c.EmailStructureValid = 1 and MarketableByEmail = 1 and hardbounced = 0
---------------------------------------------------------------------------------------------------------
--------------------------Pull through Not Earned on MY Rewards DD --------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#NotEarned') is not null
									drop table #NotEarned
Select	c.FanID,
		c.Email,
		Day65AccountNo,
		Day65AccountName
Into #NotEarned
From (
Select FanID,
		AccountNo as Day65AccountNo,
		Replace(a.AccountName,' account','') as Day65AccountName
from
(
Select *,
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY BankAccountID ASC) AS RowNo
from Staging.Customer_DDNotEarned
Where ChangeDate = DATEADD(dd, -66, DATEDIFF(dd, 0, Cast(getdate() as date)))
) as a
Where RowNo = 1
) as a
inner join Warehouse.relational.Customer as c
	on a.FanID = c.FanID
Where	c.CurrentlyActive = 1 and
		c.EmailStructureValid = 1 and 
		hardbounced = 0
---------------------------------------------------------------------------------------------------------
--------------------------Pull through Not Earned on MY Rewards DD --------------------------------------
---------------------------------------------------------------------------------------------------------
Select * From #NotEarned
Where Day65AccountName Like 'Reward%'
---------------------------------------------------------------------------------------------------------
--------------------------------------------------DOB ---------------------------------------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#DOB') is not null drop table #DOB

Select	r.FanID,
		c.Email,
		--r.MembersAssignedBatch,
		DateAdd(day,1,DOB) as DOB
Into #Dob
from Warehouse.relational.RedemptionCode as r
inner join warehouse.relational.customer as c
	on  r.FanID = c.FanID
Where	Month(c.DOB) = Month(Cast(dateadd(day,-1,getdate()) as date)) and
		Day(c.DOB) = Day(Cast(dateadd(day,-1,getdate()) as date)) and
		c.CurrentlyActive = 1 and
		c.EmailStructureValid = 1 and
		hardbounced = 0
---------------------------------------------------------------------------------------------------------
--------------------------Pull through Not Earned on MY Rewards DD --------------------------------------
---------------------------------------------------------------------------------------------------------
Select * From #DOB
