/*
		Author:			Stuart Barnley

		Date:			29th April 2016

		Purpose:		Find the customer who have earned for the first time on paid for 
						Direct Debit.

		Update:			SB 2017-07-03 - Amendment made to include both DD trans (3% and 2%)
		

*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_FirstEarnDD]
with Execute as owner
As
---------------------------------------------------------------------------------------------------------
---------------------Customers who are MyRewards DD Customers who have never earnt-----------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#DDCustomers') is not null drop table #DDCustomers
Select a.FanID
Into #DDCustomers
From [Staging].[SLC_Report_DailyLoad_Phase2DataFields] as a with (nolock)
Left Outer join Staging.Customer_FirstEarnDDPhase2 as b with (nolock)
	on a.fanid = b.fanid
where	a.LoyaltyAccount = 1 and
		b.FanID is null

Create Clustered Index i_DDCustomers_FanID on #DDCustomers (FanID)

---------------------------------------------------------------------------------------------------------
-------------------Transaction type entries that relate to Paid for DD incentivisation-------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#TranTypes') is not null drop table #TranTypes
Select	TransactionTypeID,
		ItemID
Into #TranTypes
From Relational.AdditionalCashbackAwardType with (nolock)
Where /*Title */[Description] Like '%Direct Debit%MyRewards%' --****** Changed as new title does not include the word MyRewards

Create Clustered Index i_#TranTypes_AllFields on #TranTypes (TransactionTypeID,ItemID)

---------------------------------------------------------------------------------------------------------
---------------------Customers who are MyRewards DD Customers who have never earnt-----------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#Trans') is not null drop table #Trans

Select	Distinct
		c.FanID,
		t.ProcessDate,
		t.IssuerBankAccountID
Into #Trans
from #TranTypes as tt with (nolock)
inner hash join SLC_Report.dbo.Trans as t  with (nolock)
	on	t.TypeID = tt.TransactionTypeID and
		t.ItemID = tt.ItemID
inner join #DDCustomers as c  with (nolock)
	on	c.FanID = t.FanID
Where	Cast(t.ProcessDate as date) = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0)

---------------------------------------------------------------------------------------------------------
-------------------------- Find the bank accounts that have earned cashback -----------------------------
---------------------------------------------------------------------------------------------------------

if object_id('tempdb..#BankAccounts') is not null drop table #BankAccounts
Select	*,
		ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Case
															When MyRewardAccount like '%Black%' then 0
															When MyRewardAccount like '%Platin%' then 1
															When MyRewardAccount like '%Silver%' then 2
															When MyRewardAccount like '%Reward%' then 3
															Else 99
													  End ASC) AS RowNo
Into #BankAccounts
From
(
Select  Distinct
		FanID,
		0.00 as FirstEarnValue,
		Dateadd(day,DATEDIFF(dd, 0, GETDATE())-1,0) as FirstEarndate,
		ba.BankAccountID,
		Case
			When ea.AccountType is null then ''
			Else replace(ea.AccountName,' Account','')
		End as MyRewardAccount
from #Trans as t
inner join SLC_Report.dbo.IssuerBankAccount as iab with (nolock)
	on t.IssuerBankAccountID = iab.ID
inner join SLC_Report.dbo.BankAccountTypeHistory as ba with (nolock)
	on iab.BankAccountID = ba.BankAccountID and EndDate is null
Left Outer join Staging.DirectDebit_EligibleAccounts as ea with (nolock)
	on	ba.Type = ea.AccountType and
		ea.AccountType like 'Q_' -- Only paid for accounts
) as a

---------------------------------------------------------------------------------------------------------
---------------------------- Add entry to indicate earn for the first time ------------------------------
---------------------------------------------------------------------------------------------------------

Insert into Staging.Customer_FirstEarnDDPhase2
Select	FanID,
		FirstEarnValue,
		FirstEarndate,
		BankAccountID,
		MyRewardAccount

from #BankAccounts as ba
Where RowNo = 1