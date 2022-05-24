CREATE PROCEDURE [Staging].[SSRS_R0183_LionSendVolumes]					
AS
Begin

IF OBJECT_ID ('tempdb..#EmailSendRank') IS NOT NULL DROP TABLE #EmailSendRank
Select Distinct 
	   Top 5 
	   EmailSendDate
	 , Dense_Rank() Over (Order by EmailSendDate Desc) as EmailSendDateRank
Into #EmailSendRank
From Warehouse.Staging.R_0183_LionSendVolumesCheck
Order by EmailSendDate Desc

Declare @ThisEmailSendDate Date = (Select EmailSendDate From #EmailSendRank Where EmailSendDateRank = 1)
	  , @PreviousEmailSendDate Date = (Select EmailSendDate From #EmailSendRank Where EmailSendDateRank = 2)
	  , @PreviousFourEmailSendDates Date = (Select EmailSendDate From #EmailSendRank Where EmailSendDateRank = 5)
	  
IF OBJECT_ID ('tempdb..#SSRSReportColours') IS NOT NULL DROP TABLE #SSRSReportColours
Select cl.ID as ColourListID, LOWER(cl.ColourHexCode) as ColourHexCode, DENSE_RANK() Over (Order by cl.ID) as ColourRowNo, cls.ID as SecondaryColourID, LOWER(cls.ColourHexCode) as SecondaryColourHexCode, ColourGroupID
Into #SSRSReportColours
from warehouse.apw.ColourList cl
inner join Warehouse.apw.colourlistsecondary cls on
	cl.id=cls.colourlistID
where cl.ID in (1,2,3,4,5,6,7,100,25,50)

IF OBJECT_ID ('tempdb..#AllLionSendInformation') IS NOT NULL DROP TABLE #AllLionSendInformation
Select	  Cast(LionSendID as varchar(5)) as LionSendID
		, Cast(EmailSendDate as varchar(15)) as EmailSendDate
		, Brand
		, Loyalty
		, UsersSelectedForLionSend
		, SUM(UsersSelectedForLionSend) Over (Partition by LionSendID) as UsersSelectedForLionSendTotal
		, SUM(UsersSelectedForLionSend) Over (Partition by EmailSendDate) as UsersSelectedForLionSendTotalByDate
		, UsersUploadedSFD
		, SUM(UsersUploadedSFD) Over (Partition by LionSendID) as UsersUploadedSFDTotal
		, UsersAfterSFDValidation
		, SUM(UsersAfterSFDValidation) Over (Partition by LionSendID) as UsersAfterSFDValidationTotal
		, UsersEmailed
		, SUM(UsersEmailed) Over (Partition by LionSendID) as UsersEmailedTotal
		, LionSendColour
		, BrandColour
		, LoyaltyColour
		, SendPeriodPreviousMonth
		, SendPeriodPreviousFourMonths
Into #AllLionSendInformation
From	(
		Select Distinct
			  LionSendID
			, EmailSendDate
			, Brand
			, Loyalty
			, Cast(UsersSelectedForLionSend as INT) as UsersSelectedForLionSend
			, Cast(UsersUploadedSFD as INT) as UsersUploadedSFD
			, Cast(UsersAfterSFDValidation as INT) as UsersAfterSFDValidation
			, Cast(UsersEmailed as INT) as UsersEmailed
			, rc.ColourHexCode as LionSendColour
			, BrandColour
			, LoyaltyColour
			, Case 
				When ThisEmailSendDate=EmailSendDate then 'This Send Date'
				When PreviousEmailSendDate=EmailSendDate then 'Previous Send Date'
				Else NULL
			  End as SendPeriodPreviousMonth
			, Case 
				When ThisEmailSendDate=EmailSendDate then 'This Send Date'
				When ThisEmailSendDate<>EmailSendDate AND EmailSendDate>=PreviousFourEmailSendDates then 'Previous Four Send Dates'
				Else NULL
			  End as SendPeriodPreviousFourMonths
		From
			(
			Select Distinct
					  LionSendID
					, EmailSendDate
					, Brand
					, Loyalty
					, UsersSelectedForLionSend
					, UsersUploadedSFD
					, UsersAfterSFDValidation
					, UsersEmailed
					, (DENSE_RANK() Over (Order by LionSendID) % 8) + 1 as LionSendRank
					, Case
						When Brand='NatWest' then '#7a7a7a'
						When Brand='RBS' then '#5c5c5c'
					  End as BrandColour
					, Case
						When Loyalty='Core' then '#bcbcbc'
						When Loyalty='Prime' then '#9d9d9d'
					  End as LoyaltyColour
					, @ThisEmailSendDate as ThisEmailSendDate
					, @PreviousEmailSendDate as PreviousEmailSendDate
					, @PreviousFourEmailSendDates as PreviousFourEmailSendDates
			From Warehouse.Staging.R_0183_LionSendVolumesCheck lsvc
			) lsvc2
		Left Join #SSRSReportColours rc on
			lsvc2.LionSendRank=rc.ColourRowNo
	) [all]
WHERE CONVERT(DATE, EmailSendDate) >= DATEADD(MONTH, -6, GETDATE())

Select	  LionSendID = CONVERT(INT, LionSendID)
		, EmailSendDate
		, Brand
		, Loyalty
		, UsersSelectedForLionSend
		, UsersSelectedForLionSendTotal
		, UsersUploadedSFD
		, UsersUploadedSFDTotal
		, UsersAfterSFDValidation
		, UsersAfterSFDValidationTotal
		, UsersEmailed
		, UsersEmailedTotal
		, LionSendColour
		, BrandColour
		, LoyaltyColour
		, SendPeriodPreviousMonth
		, SendPeriodPreviousFourMonths		
		, Case 
			When SendPeriodPreviousFourMonths = 'This Send Date' Then LionSendID
			When SendPeriodPreviousFourMonths = 'Previous Four Send Dates' Then (select distinct stuff(( select Distinct ',' + LionSendID
																											from #AllLionSendInformation [all]
																											where LionSendID = LionSendID
																											And SendPeriodPreviousFourMonths = 'Previous Four Send Dates'
																											for xml path(''))
																										,1,1,'') as LionSendIDs
																				 from #AllLionSendInformation )
			Else NULL
			End as SendPeriodPreviousFourMonthsLionSendID
		, Case 
			When SendPeriodPreviousFourMonths = 'This Send Date' Then EmailSendDate
			When SendPeriodPreviousFourMonths = 'Previous Four Send Dates' Then (select MIN(EmailSendDate) from #AllLionSendInformation where SendPeriodPreviousFourMonths = 'Previous Four Send Dates')
																			  + ' to '
																			  + (select MAX(EmailSendDate) from #AllLionSendInformation where SendPeriodPreviousFourMonths = 'Previous Four Send Dates')
			Else NULL
			End as SendPeriodPreviousFourMonthsEmailSendDate
		 
		 , Min_UsersSelectedForLionSendTotalByDate  = FLOOR((SELECT MIN(UsersSelectedForLionSendTotalByDate) FROM #AllLionSendInformation) / 10000) * 10000
		 , Max_UsersSelectedForLionSendTotalByDate  = CEILING((SELECT MAX(UsersSelectedForLionSendTotalByDate) FROM #AllLionSendInformation) / 10000) * 10000 + 10000
From #AllLionSendInformation
Order by EmailSendDate DESC, CONVERT(INT, LionSendID) desc, Brand, Loyalty

End