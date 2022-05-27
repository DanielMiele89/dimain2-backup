/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to nfi.Relational.campaignhistory for new IronOfferCyclesIDs in nFI.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added distinct constraint to fetch
	- Added intermediate table to loop for optimisation purposes

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table
******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_nFINonAAM_Load_Exposed_Members
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to nfi.Relational.campaignhistory for new IronOfferCyclesIDs added to nFI.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

	Declare @IOCID int = (Select Max(IronOfferCyclesID) From nfi.Relational.campaignhistory)+1;
	Declare @IOCID_Max int = (Select Max(IronOfferCyclesID) From nFi.Relational.IronOfferCycles);

	-- Do loop

	While @IOCID <= @IOCID_Max
	
	Begin

		If not exists (Select null from nfi.Relational.campaignhistory where ironoffercyclesid = @IOCID)
		
		Begin

			If object_id('tempdb..#CampaignHistoryStaging') is not null drop table #CampaignHistoryStaging;
		
			Select distinct
				ioc.ironoffercyclesid
				,f.ID as FanID
			Into #CampaignHistoryStaging
			From nFI.relational.ironoffercycles ioc
			Inner join slc_report.dbo.IronOfferMember iom
				on ioc.ironofferid = iom.IronOfferID
			Inner join slc_report.dbo.Fan f
				on iom.CompositeID = f.compositeid
			Inner join nfi.relational.offercycles as oc
				on ioc.OfferCyclesID = oc.OfferCyclesID
			Where
				ironoffercyclesid = @IOCID
				And iom.StartDate <= oc.EndDate
				And (iom.EndDate >= oc.StartDate or iom.EndDate is null);
			
			Insert into nfi.Relational.campaignhistory
			Select
				s.ironoffercyclesid
				, s.FanID
			From #CampaignHistoryStaging s;
		
			Set @IOCID = @IOCID+1;

		End

	End

	/******************************************************************************
	--Code for doing bespoke exposed member inserts

	If object_id('tempdb..#IterationTable') is not null drop table #IterationTable;
	
	Create table #IterationTable(Ironoffercyclesid int, RowNum int);
	
	Insert into #IterationTable values 
		(0000, 1), -- (IronOfferCyclesID without exposed members, Incremental row number)
		(0000, 2), 
		(0000, 3) 

	DECLARE @IronOfferCyclesID INT;
	Declare @RowNum int = (Select Min(RowNum) From #IterationTable);
	Declare @RowNum_Max int = (Select Max(RowNum) From #IterationTable);

	-- Do loop

	While	@RowNum <= @RowNum_Max
	Begin

		SET @IronOfferCyclesID = (SELECT IronOfferCyclesID FROM #IterationTable where RowNum = @RowNum);

		Insert into nfi.Relational.campaignhistory
		Select
			ioc.ironoffercyclesid
			,f.ID
		From nFI.relational.ironoffercycles ioc
		Inner join slc_report.dbo.IronOfferMember iom
			on ioc.ironofferid = iom.IronOfferID
		Inner join slc_report.dbo.Fan f
			on iom.CompositeID = f.compositeid
		Inner join nfi.relational.offercycles as oc
			on ioc.OfferCyclesID = oc.OfferCyclesID
		Where
			ironoffercyclesid = @IronOfferCyclesID
			and iom.StartDate <= oc.StartDate
			and (iom.EndDate is null or iom.EndDate > oc.StartDate);
		
		Set @RowNum = @RowNum+1;

	End
	******************************************************************************/

END