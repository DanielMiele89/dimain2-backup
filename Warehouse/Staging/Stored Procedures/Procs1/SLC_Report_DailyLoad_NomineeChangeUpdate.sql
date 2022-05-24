/*
	Author:		Stuart	Barnley

	Date:		12th January 2016

	Purpose:	When Phase 2 account is opened but on what was a phase 1 account they are deemed to have
				had a nominee change by RBSG. This is because their previous entry was closed and the
				new one written into slc_report.dbo.DDCashbackNominee
				


*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_NomineeChangeUpdate]
with Execute as owner
As

DECLARE @TodayDate DATE = GETDATE()
	,	@Yesterday DATETIME = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0)
	,	@TwoDaysAgo DATETIME = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-2,0)

SELECT @TwoDaysAgo

--------------------------------------------------------------------------------------------------------
-----------------------------------------Find RBSG Nominee Changes--------------------------------------
--------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Customers') is not null drop table #Customers

select Distinct FanID,
				ic.ID as IssuerCustomerID
Into #Customers
from slc_report.dbo.FanSFDDailyUploadData_DirectDebit as dd
inner join slc_report.dbo.fan as f
	on dd.FanID = f.ID
inner join slc_Report.dbo.IssuerCustomer as ic
	on f.SourceUID = ic.SourceUID and
		(Case
			When ClubID = 132 then 2
			Else 1
		 End) = ic.IssuerID
Where RBSNomineeChange = 1
--------------------------------------------------------------------------------------------------------
-----------------------------------------Add Index to Customer Table------------------------------------
--------------------------------------------------------------------------------------------------------
Create Clustered Index IX_Customers_ID on #Customers (IssuerCustomerID)
--------------------------------------------------------------------------------------------------------
-----------------------------------------Find Nominee Change Accounts-----------------------------------
--------------------------------------------------------------------------------------------------------
if object_id('tempdb..#BA') is not null drop table #BA
Select FanID,c.IssuerCustomerID,BankAccountID
Into #BA
From #Customers as c
inner join slc_report.dbo.DDCashbackNominee as n
	on	c.IssuerCustomerID = n.IssuerCustomerID and
		Dateadd(day,DATEDIFF(dd, 0, n.ChangedDate)-0,0) = @Yesterday
--------------------------------------------------------------------------------------------------------
------------------------------------Isolate Accounts That have changed Types----------------------------
--------------------------------------------------------------------------------------------------------
if object_id('tempdb..#BackAccountChanges') is not null drop table #BackAccountChanges
Select Distinct FanID
Into #BackAccountChanges
from #BA as a
inner join SLC_Report.dbo.BankAccountTypeHistory as b
	on a.BankAccountID = b.BankAccountID
Where EndDate is null and StartDate >= @TwoDaysAgo
--------------------------------------------------------------------------------------------------------
-------------------------------------Find date of previous entry to assess------------------------------
--------------------------------------------------------------------------------------------------------
if object_id('tempdb..#LastED') is not null drop table #LastED

Select	a.FanID,
		a.IssuerCustomerID,
		a.BankAccountID,
		Max(n.EndDate) as LastEndDates
Into #LastED
from	(Select a.FanID,
				a.IssuerCustomerID,
				a.BankAccountID
		 from #BA as a
		 Left Outer join #BackAccountChanges as b
			on a.FanID = b.FanID
		 Where b.FanID is null
		) as a
inner loop join slc_report.dbo.DDCashbackNominee as n
	on a.BankAccountID = n.BankAccountID
Group by a.FanID,
		a.IssuerCustomerID,
		a.BankAccountID
--------------------------------------------------------------------------------------------------------
--------------------------------Find entries where Nominee change to same nominee ----------------------
--------------------------------------------------------------------------------------------------------
if object_id('tempdb..#NomNotChanged') is not null drop table #NomNotChanged
Select	a.FanID,
		a.BankAccountID,
		a.IssuerCustomerID
Into	#NomNotChanged
from #LastED as a
inner join slc_report.dbo.DDCashbackNominee as b
	on	a.LastEndDates = b.EndDate and
		a.BankAccountID = b.BankAccountID
Where	a.IssuerCustomerID = b.IssuerCustomerID

--------------------------------------------------------------------------------------------------------
--------------------------------Find entries where Nominee change to same nominee ----------------------
--------------------------------------------------------------------------------------------------------

Select Distinct c.FanID
Into #FinalNomChangeUpdates
from #Customers AS c
LEFT Outer Join #BackAccountChanges as a
	on c.FanID = a.FanID
Left Outer join #NomNotChanged as n
	on c.fanid = n.FanID
Where a.FanID is null or n.FanID is null

--------------------------------------------------------------------------------------------------------
-------------------------------- Update SLC_Report Table ----------------------
--------------------------------------------------------------------------------------------------------

Update slc_report.dbo.FanSFDDailyUploadData_DirectDebit
Set RBSNomineeChange = 0
Where FanID in (Select FanID from #FinalNomChangeUpdates)