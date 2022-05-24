CREATE Procedure [Staging].[CBP_Process_CustomerJourney_and_Lapsing_SpecificDate]
					@Date Date
--with execute as owner
As
set nocount on
BEGIN
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare --@Date date,
			@RowNo Int,@LastRow int
	--Set @Date = CAST(getdate() as DATE)
	Set @RowNo = 1


	--Create Table ##Cust (FanID int, ActivatedDate Date)

	Select id as FanID,
		   AgreedTCsDate as ActivatedDate,
		   ROW_NUMBER() OVER (ORDER BY f.id) AS RowNumber

	Into ##Cust
	from slc_report.dbo.fan as f with (nolock)
	Where	f.clubid in (132,138) and 
			f.AgreedTCsDate is not null and 
			f.Status = 1

	SELECT @LastRow = @@ROWCOUNT

	create clustered index ixc_ttCust on ##Cust(RowNumber)

	While @RowNo < @LastRow
	Begin
		--exec [Staging].[CBP_Process_CustomerJourneyStages_SpecificDates] @RowNo, 50000, @Date
		Exec [Staging].[CBP_Process_CustomerLapsing_SpecificDate] @RowNo, 50000,  @Enddate = @Date
		------------------------------------------------------------------------------------------------------------------
		----------------------------------------Insert data into CustomerJourney Table------------------------------------
		------------------------------------------------------------------------------------------------------------------
		/*
		Truncate table Warehouse.Relational.CustomerJourney
		Insert Into Warehouse.Relational.CustomerJourney
		Select	a.FanID,
				a.CustomerJourneyStatus,
				b.LapsFlag, 
				a.[Date],
				Case
					When a.CustomerJourneyStatus Like 'MOT[1-3]' then 'M'+ Right(a.CustomerJourneyStatus,1)
					When Left(a.CustomerJourneyStatus,2) IN ('Re','Sa') then Left(a.CustomerJourneyStatus,1) + Left(ltrim(Right(a.CustomerJourneyStatus,10)),1)
					When Left(a.CustomerJourneyStatus,1) = 'D' then 'D'
					Else '?'
				End + LEFT(b.LapsFlag,1) as Shortcode,
				@Date as StartDate,
				Cast(null as Date) as EndDate
		into #CustomerJourney
		from dbo.CustomerJourneyStaging as a
		inner join dbo.CustomerLapse as b
			on a.FanID = b.fanid

		truncate table dbo.CustomerJourneyStaging
		truncate table dbo.CustomerLapse
		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Delete Matched Table--------------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		--If process has already been run delete new entries added today
		Delete from dbo.CustomerJourney
		from dbo.CustomerJourney as cj
		inner join dbo.CustomerJourneyStaging as cjs
			on	cj.FanID = cjs.FanID and
				cj.[StartDate] = cjs.[Date]
		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Update Old Statuses Table---------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		Update /*dbo.[CustomerJourney] */cj
		Set EndDate = Dateadd(Day,-1,@Date)
		from dbo.[CustomerJourney] as CJ
		inner join #CustomerJourney as a
			on	cj.FanID = a.FanID and
				cj.ShortCode <> a.ShortCode and
				cj.EndDate is null
		Left Outer join dbo.[CustomerJourney] as cj2
			on  cj2.fanid = a.FanID and
				Left(a.ShortCode,1) = 'M' and Left(cj2.ShortCode,1) not in  ('M','D')
		Where cj2.FanID is null

		------------------------------------------------------------------------------------------------------------------
		--------------------------------------------Insert new Statuses---------------------------------------------
		------------------------------------------------------------------------------------------------------------------
		Insert into dbo.[CustomerJourney] (FanID,CustomerJourneyStatus,LapsFlag,Date,Shortcode,StartDate,EndDate)

		Select a.FanID,a.CustomerJourneyStatus,a.LapsFlag,a.Date,a.Shortcode,a.StartDate,a.EndDate
		from #CustomerJourney as a
		Left Outer Join dbo.CustomerJourney as CJ
			on	cj.FanID = a.FanID and
				cj.ShortCode = a.ShortCode and
				cj.EndDate is null
		--Check that not been devolved back to Nursery
		Left Outer join dbo.CustomerJourney as cj2
			on  cj2.fanid = a.FanID and
				Left(a.ShortCode,1) = 'M' and Left(CJ2.ShortCode,1) not in  ('M','D')
		Where cj.FanID is null and cj2.FanID is null

		------------------------------------------------------------------------------------------------------------------
		-----------------------------------------Repopulate Nominated members Table---------------------------------------
		------------------------------------------------------------------------------------------------------------------
		--Truncate table dbo.NominatedMember

		--Insert Into dbo.NominatedMember
		--Select	CompositeID,
		--		cj.ShortCode
		--from dbo.CustomerJourney as cj
		--inner join dbo.fan as f
		--	on cj.fanid = f.id
		--Where enddate is null

		update f
			set f.CustomerJourneyStatus = cj.ShortCode
		from dbo.CustomerJourney cj
		inner join dbo.fan f with (index=1) on cj.fanid = f.id
		Where cj.enddate is null
		
		Drop table #CustomerJourney
		*/
		Set @RowNo = @RowNo+50000
	End

	Drop table ##Cust
End
