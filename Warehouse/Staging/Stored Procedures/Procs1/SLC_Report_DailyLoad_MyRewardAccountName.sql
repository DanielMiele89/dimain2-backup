/*
		
		Author:			Stuart Barnley

		Date:			29th April 2016
		
		Purpose:		Populate MyReward Account name into MyRewardAccount

		Update:			N/A

*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_MyRewardAccountName]
With Execute as Owner
As
---------------------------------------------------------------------------------------------------------
------------------------------- Pull a list of Loyalty Accounts - up-to-three----------------------------
---------------------------------------------------------------------------------------------------------

	if object_id('tempdb..#BankAccounts') is not null drop table #BankAccounts
	Select a.FanID,AccountName1
	Into #BankAccounts
	From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
	inner join Staging.SLC_Report_DailyLoad_Phase2DataFields as b
		on a.FanID = b.FanID
	Where	b.LoyaltyAccount = 1 and
			b.MyRewardAccount = '' and
			a.AccountName1 like 'Reward%'
	Union All
	Select a.FanID,AccountName2
	From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
	inner join Staging.SLC_Report_DailyLoad_Phase2DataFields as b
		on a.FanID = b.FanID
	Where	b.LoyaltyAccount = 1 and
			b.MyRewardAccount = '' and
			a.AccountName2 like 'Reward%'
	Union All
	Select a.FanID,AccountName3
	From slc_report.dbo.FanSFDDailyUploadData_DirectDebit as a
	inner join Staging.SLC_Report_DailyLoad_Phase2DataFields as b
		on a.FanID = b.FanID
	Where	b.LoyaltyAccount = 1 and
			b.MyRewardAccount = '' and
			a.AccountName3 like 'Reward%'

---------------------------------------------------------------------------------------------------------
-------------------------------------- Pick highest ranked account --------------------------------------
---------------------------------------------------------------------------------------------------------
if object_id('tempdb..#BankAccounts_Distinct') is not null drop table #BankAccounts_Distinct

	Select	a.FanID,
			Replace(a.AccountName1,' Account','') as MyRewardAccount 
	Into #BankAccounts_Distinct
	From
	(
	Select	a.*,
			ROW_NUMBER() OVER(PARTITION BY FanID ORDER BY Case
																When AccountName1 like '%Black%' then 0
																When AccountName1 like '%Plat%' then 1
																When AccountName1 like '%Silver%' then 2
																When AccountName1 like '%Reward%' then 3
																Else 4
														  End ASC) AS RowNo
	from #BankAccounts as a
	) as a
	Where	a.RowNo = 1

---------------------------------------------------------------------------------------------------------
-------------------------------------- Update MyRewardAccount field -------------------------------------
---------------------------------------------------------------------------------------------------------

	Update b
	Set b.MyRewardAccount = a.MyRewardAccount
	From Staging.SLC_Report_DailyLoad_Phase2DataFields as b with (Nolock)
	inner join  #BankAccounts_Distinct as a
		on a.FanID = b.FanID
	Where Len(b.MyRewardAccount) = 0