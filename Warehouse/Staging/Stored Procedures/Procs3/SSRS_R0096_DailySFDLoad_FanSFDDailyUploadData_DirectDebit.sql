
CREATE Procedure Staging.SSRS_R0096_DailySFDLoad_FanSFDDailyUploadData_DirectDebit
as
Select	'FanSFDDailyUploadData_DirectDebit - Latest' as DataDate,
		Sum(cast(OnTrial as int)) as OnTrial,
		Sum(Cast(Nominee as int)) as Nominees,
		Sum(Case
				When FirstDDEarn is not null then 1
				Else 0
			End) as FirstDDEarn_Count,
		Max(FirstDDEarn) as FirstDDEarn_LatestDate,
		Sum(Case 
				When FirstDDEarn = dateadd(day,-1,Cast(getdate() as date)) then 1
				Else 0
			End) as FirstEarn_Yesterday,
		Sum(Case 
				When Len(AccountName1) > 0 then 1
				Else 0
			End) as AccountName1,
		Sum(Case 
				When Len(AccountName2) > 0 then 1
				Else 0
			End) as AccountName2,
		Sum(Case 
				When Len(AccountName3) > 0 then 1
				Else 0
			End) as AccountName3
		from [Staging].[FanSFDDailyUploadData_DirectDebit]
Union All
Select	'FanSFDDailyUploadData_DirectDebit - Previous' as DataDate,
		Sum(cast(OnTrial as int)) as OnTrial,
		Sum(Cast(Nominee as int)) as Nominees,
		Sum(Case
				When FirstDDEarn is not null then 1
				Else 0
			End) as FirstDDEarn_Count,
		Max(FirstDDEarn) as FirstDDEarn_LatestDate,
		Sum(Case 
				When FirstDDEarn = dateadd(day,-1,Cast(getdate() as date)) then 1
				Else 0
			End) as FirstEarn_Yesterday,
		Sum(Case 
				When Len(AccountName1) > 0 then 1
				Else 0
			End) as AccountName1,
		Sum(Case 
				When Len(AccountName2) > 0 then 1
				Else 0
			End) as AccountName2,
		Sum(Case 
				When Len(AccountName3) > 0 then 1
				Else 0
			End) as AccountName3
		from [Staging].[FanSFDDailyUploadData_DirectDebit_PreviousDay]