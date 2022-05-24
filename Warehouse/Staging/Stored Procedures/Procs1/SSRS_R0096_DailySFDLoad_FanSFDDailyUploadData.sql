CREATE Procedure Staging.SSRS_R0096_DailySFDLoad_FanSFDDailyUploadData
as
Select	'FanSFDDailyUploadData - Latest' as DataDate,
		Count(*) as Customers,
		Sum(Clubcashavailable) as ClubCashbavailable,
		Sum(ClubCashPending) as ClubCashPending,
		Max(Case
				When Left(CJS,2) = 'M1' then ClubCashPending
				Else NULL
			End) as ClubCashPendingM1,
		Max(Case
				When Left(CJS,2) = 'M1' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM1,
		Max(Case
				When Left(CJS,2) = 'M2' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM2_Max,
		Min(Case
				When Left(CJS,2) = 'M3' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM3_Min,
		Max(Case
				When Left(CJS,2) = 'M3' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM3_Max
from [Staging].[FanSFDDailyUploadData] as a

Union All

Select	'FanSFDDailyUploadData - Previous' as DataDate,
		Count(*) as Customers,
		Sum(Clubcashavailable) as ClubCashbavailable,
		Sum(ClubCashPending) as ClubCashPending,
		Max(Case
				When Left(CJS,2) = 'M1' then ClubCashPending
				Else NULL
			End) as ClubCashPendingM1,
		Max(Case
				When Left(CJS,2) = 'M1' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM1,
		Max(Case
				When Left(CJS,2) = 'M2' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM2_Max,
		Min(Case
				When Left(CJS,2) = 'M3' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM3_Min,
		Max(Case
				When Left(CJS,2) = 'M3' then ClubCashAvailable
				Else NULL
			End) as ClubCashAvailableM3_Max
from [Staging].[FanSFDDailyUploadData_PreviousDay] as a
