
/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Add exposed members to [WH_Visa].[Report].[CampaignHistory] for new IronOfferCyclesIDs in nFI.Relational.ironoffercycles
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 16/05/2018
	- Added distinct constraint to fetch
	- Added intermediate table to loop for optimisation purposes

Jason Shipp 11/07/2018
	- Added logic to only insert new exposed members if the IronOfferCyclesID does not already exists in the campaignhistory table
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VisaBarclaycardNonAAM_Load_Exposed_Members_20220407]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Add exposed members to [WH_Visa].[Report].[CampaignHistory] for new IronOfferCyclesIDs added to nFI.Relational.ironoffercycles
	******************************************************************************/

	-- Declare iteration variables

	Declare @IOCID int = (Select COALESCE(Max(IronOfferCyclesID), 0) From [WH_Visa].[Report].[CampaignHistory])+1;
	Declare @IOCID_Max int = (Select Max(IronOfferCyclesID) From [WH_Visa].[Report].[IronOfferCycles]);

	-- Do loop

	While @IOCID <= @IOCID_Max
	
	Begin

		If not exists (Select null from [WH_Visa].[Report].[CampaignHistory] where IronOfferCyclesID = @IOCID)
		
		Begin

			If object_id('tempdb..#CampaignHistoryStaging') is not null drop table #CampaignHistoryStaging;
		
			Select distinct
				ioc.ironoffercyclesid
				,cu.FanID
			Into #CampaignHistoryStaging
			From [WH_Visa].[Report].[IronOfferCycles] ioc
			Inner join [WH_Visa].[Derived].[IronOfferMember] iom
				on ioc.IronOfferID = iom.IronOfferID
			Inner join [WH_Visa].[Derived].[Customer] cu
				on iom.CompositeID = cu.CompositeID
			Inner join [WH_Visa].[Report].[OfferCycles] as oc
				on ioc.OfferCyclesID = oc.OfferCyclesID
			Where
				ironoffercyclesid = @IOCID
				And iom.StartDate <= oc.EndDate
				And (iom.EndDate >= oc.StartDate or iom.EndDate is null);
			
			Insert into [WH_Visa].[Report].[CampaignHistory]
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

		Insert into [WH_Visa].[Report].[CampaignHistory]
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