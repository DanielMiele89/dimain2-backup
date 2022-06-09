

--=====================================================================
--SP Name : [dbo].[CBP_Process_CustomerJourneyStages_SFD]
--Description: Populates the CBP_CustomerUpdate_CJS table with the new CJS values
-- Update Log
--		Stuart - 19/08/2014 - Algorithm code
--		Ed - 21/08/2014 - Created SP and insert
--		Nitin - 02/09/2014 - Replace use of ##Cust and #CB table with FanSFDDailyUploadDataStaging
--		Stuart - 31/03/2015 - Changed to deal with new reduced frequency requirement
--=====================================================================
CREATE PROCEDURE [dbo].[__CBP_Process_CustomerJourneyStages_SFD]
    @RowNo		INT,
    @interval	INT
AS
BEGIN
	SET NOCOUNT ON

	--Declare @RowNo int, @Interval int
	--Set @RowNo = 1
	--Set @Interval = 50000

	------------------------------------------------------------------------------------------------------------
	------------------------------------------------CustomerBase------------------------------------------------
	------------------------------------------------------------------------------------------------------------
	INSERT INTO dbo.CBP_CustomerUpdate_CJS (FanID, CJS, WeekNumber)
	Select		FanID,
				'SAV' as CJS,
				--Case
				--	  When cjs.CustomerJourneyStatus = 'MOT1' and MOT1_Cycles >  1	then 'M1O'
				--	  When cjs.CustomerJourneyStatus = 'MOT1' and MOT1_WeekNo >= 3	then 'M1O'
				--	  When cjs.CustomerJourneyStatus = 'MOT2' and MOT2_Cycles >  1	then 'M2O'
				--	  When cjs.CustomerJourneyStatus = 'MOT2' and MOT2_WeekNo >= 4	then 'M2O'
				--	  When cjs.CustomerJourneyStatus = 'MOT3' and MOT3_WeekNo >= 1	then 'SAV'
				--	  When Left(cjs.CustomerJourneyStatus,1) = 'M'					Then 'M'+Right(cjs.CustomerJourneyStatus,1)
				--	  When Left(cjs.CustomerJourneyStatus,1) = 'R'					Then 'RED'
				--	  When Left(cjs.CustomerJourneyStatus,1) = 'S'					Then 'SAV'
				--	  Else ''
				--End as CJS,
				0 as WeekNumber
				--Case
				--	  When cjs.CustomerJourneyStatus = 'MOT1' and MOT1_Cycles >  1		then 0
				--	  When cjs.CustomerJourneyStatus = 'MOT1' and MOT1_WeekNo >= 3		then 0
				--	  When cjs.CustomerJourneyStatus = 'MOT2' and MOT2_Cycles >  1		then 0
				--	  When cjs.CustomerJourneyStatus = 'MOT2' and MOT2_WeekNo >= 4		then 0
				--	  When cjs.CustomerJourneyStatus = 'MOT3' and MOT3_WeekNo >= 1		then 0
				--	  When cjs.CustomerJourneyStatus = 'MOT1' and MOT1_WeekNo is null	then 1
				--	  When cjs.CustomerJourneyStatus = 'MOT1'							Then MOT1_WeekNo+1
				--	  When cjs.CustomerJourneyStatus = 'MOT2' and MOT2_WeekNo is null	then 1
				--	  When cjs.CustomerJourneyStatus = 'MOT2'							Then MOT2_WeekNo+1
				--	  When cjs.CustomerJourneyStatus = 'MOT3' and MOT3_WeekNo is null	then 1
				--	  When cjs.CustomerJourneyStatus = 'MOT3'							Then MOT3_WeekNo+1
				--	  When Left(cjs.CustomerJourneyStatus,1) in ('R','S')				Then 0
				--	  Else ''
				--End as WeekNumber
	from FanSFDDailyUploadDataStaging as c
	--inner join dbo.CustomerJourneyStaging as CJS
	--	  on c.FanID = cjs.FanID
	--Left Outer join DIMain.Warehouse.Staging.CustomerJourney_MOTWeekNos as M with (Nolock)
	--	  on cjs.FanID = M.FanID
	--Where customerjourneystatus <> 'deactivated'
End
