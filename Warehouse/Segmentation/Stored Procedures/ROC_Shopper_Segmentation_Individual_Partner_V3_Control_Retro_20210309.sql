﻿
/******************************************************************************
Author:	Stuart Barnley
Created: 19/10/2016
Purpose: 
	- Segments control group universe based on members' most recent spend at the given retailer ConsumerCombinationIDs in the Warehouse.Relational.ConsumerTransaction table
	- Segmented members loaded into a new table

------------------------------------------------------------------------------
Modification History

Jason Shipp 13/04/2018
	- Formatted code to make it more readable

Jason Shipp 16/05/2018 
	- Added CINID to final table load, for adding to controlgroupmembers tables

Jason Shipp 01/06/2018 
	- Fed Shopper column from Segmentation.ROC_Shopper_Segment_Partner_Settings into segmentation logic

Jason Shipp 31/01/2019
	- Added GROUP BY CINID to insert into #Spenders to avoid duplicate CINID values being inserted

Jason Shipp 28/02/2019
	- Fixed bug in the previous update! Ensured CINIDs and FanIDs are inserted into #Spenders in the correct order

Jason Shipp 06/09/2019
	- Added logic to control source of control group members, based on whether the retailer needs a bespoke (in programme) control group or not
	- Normal member source: Warehouse.Segmentation.ROC_Shopper_Segment_CtrlGroup
	- Bespoke member source: [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram]
	- Bespoke member source fallback: Warehouse.Staging.ControlGroupInProgramme_Fallback: this table must be manually maintained

Hayden Reid 16/10/2020
	- Changed error logic to use THROW instead of RETURN

******************************************************************************/

CREATE PROCEDURE [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro_20210309] (
		@PartnerNo int,
		@EnDate Date,
		@TName varchar(200)
		)

WITH EXECUTE AS OWNER

AS
BEGIN
	
	IF @PartnerNo IN (SELECT PartnerID FROM Warehouse.Segmentation.PartnerSettings_DD)
		-- Exit stored procedure if MFDD partner
		THROW 50001
			, 'This is an MFDD partner: segment using Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD instead'
			, 1
	

	---- For testing
	--DECLARE @PartnerNo int = 4263
	--DECLARE @EnDate Date = '2019-08-15'
	--DECLARE @TName varchar(200) = 'Sandbox.ProcessOp.Control426320190815'	

	Declare 
		@PartnerID int
		, @BrandID int
		, @Today datetime
		, @time datetime
		, @msg varchar(2048)
		, @TableName varchar(50)
		, @EndTime datetime
		, @EndDate date = @EnDate

	Set	@Today = getdate();
	Set	@PartnerID = @PartnerNo;
	Set @TableName = 'Roc_Shopper_Segment_Members - '+Cast(@PartnerID as Varchar(5));
	
	/******************************************************************************
	Write Entry to Joblog_Temp
	******************************************************************************/
	
	Insert into Staging.JobLog_Temp
	Select
		StoredProcedureName = 'ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro'
		, TableSchemaName = 'Segmentation'
		, TableName = @TableName
		, StartDate = @Today
		, EndDate = NULL
		, TableRowCount = NULL
		, AppendReload = 'A';

	/******************************************************************************
	Load cycle start dates
	******************************************************************************/

	-- Declare Vaiables

	DECLARE @OriginCycleEndDate DATE = '2010-02-10'; -- Hardcoded random Campaign Cycle start date
	
	-- Use recursive CTE to fetch start and end dates of previous complete Campaign Cycles

	IF OBJECT_ID('tempdb..#CycleEndDates') IS NOT NULL DROP TABLE #CycleEndDates;

	WITH cte AS
		(SELECT @OriginCycleEndDate AS CycleEndDate -- anchor member
		UNION ALL
		SELECT CAST((DATEADD(WEEK, 4, CycleEndDate)) AS DATE) --  Campaign Cycle start date: recursive member
		FROM   cte
		WHERE  CAST((DATEADD(WEEK, 4, CycleEndDate)) AS DATE) <= DATEADD(week, 8, @Today) -- terminator: last complete cycle end date
		)
	SELECT
		(cte.CycleEndDate) AS CycleEndDate
	INTO #CycleEndDates
	FROM cte
	OPTION (MAXRECURSION 1000);

	DECLARE @CycleEndDate date = (SELECT MIN(CycleEndDate) FROM #CycleEndDates WHERE CycleEndDate >= @EndDate); -- @EndDate is actually the cycle/half cycle start date
	SET @EndDate = DATEADD(day, -27, @CycleEndDate); -- Update to cycle start date

	/***********************************************************************************************
	Identify Shopper and Lapsed control members 
	***********************************************************************************************/
		
	-- Load customer Table

	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;

	CREATE TABLE #Customers (
		FanID int
		, CINID int
		, RowNo int
	);

	IF @PartnerID IN ( -- Fetch RetailerIDs and associated PartnerIDs for retailers requiring bespoke setup (in programme)
		SELECT PartnerID FROM ( 
			SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			UNION 
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			UNION
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
		) x
	)
	BEGIN
		IF @PartnerID IN ( -- Check in programme members table contains members for the retailer for Iron Offers overlapping the cycle
			SELECT DISTINCT s.PartnerID 
			FROM Warehouse.Relational.IronOfferSegment s
			INNER JOIN [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ip 
			ON s.IronOfferID = ip.IronOfferID
			WHERE 
			(s.RetailerID = @PartnerID) -- @PartnerID should by the primary PartnerID
			AND s.OfferStartDate <= @CycleEndDate
			--AND (s.OfferEndDate >= @EndDate OR s.OfferEndDate IS NULL) -- @EndDate is actually the cycle/half cycle start date
			AND CAST(ip.StartDate AS date) <= @CycleEndDate
			--AND (CAST(ip.EndDate AS date) >= @EndDate OR ip.EndDate IS NULL)
		)
		BEGIN -- Load source control group members for retailers requiring bespoke setup
			With IronOfferIDs AS (
				Select IronOfferID from Warehouse.Relational.IronOfferSegment s
				Where 
				(s.RetailerID = @PartnerID OR s.PartnerID = @PartnerID)
				AND s.OfferStartDate <= @CycleEndDate
				--AND (s.OfferEndDate >= @EndDate OR s.OfferEndDate IS NULL) -- @EndDate is actually the cycle/half cycle start date
			)
			Insert into #Customers (FanID, CINID, RowNo)
			Select 
			x.FanID
			, x.CINID
			, ROW_NUMBER() OVER(ORDER BY x.FanID DESC) AS RowNo
			From (
				Select Distinct
					cg.FanID
					, cl.CINID
				From [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
				Inner join Relational.Customer c -- Make sure in programme
					on cg.FanID = c.FanID
				Inner join SLC_Report.dbo.Fan f 
					on c.FanID = f.ID
				Inner join Relational.CINList cl
					on f.SourceUID = cl.CIN
				Where 
					cg.IronOfferID in (Select IronOfferID from IronOfferIDs)
					and cg.ExcludeFromAnalysis = 0
					and cast(cg.StartDate as date) <= @CycleEndDate
					--and (cast(cg.EndDate as date) >= @EndDate or cg.EndDate is null)
			) x;
		END
		ELSE
		BEGIN -- Load source control group members for retailers requiring bespoke setup: fallback to Warehouse.Staging.ControlGroupInProgramme_Fallback table
			Insert into #Customers (FanID, CINID, RowNo)
			Select DISTINCT
				cg.FanID
				, cl.CINID
				, ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
			From Warehouse.Staging.ControlGroupInProgramme_Fallback cg
			Inner join Relational.Customer c -- Make sure in programme
				on cg.FanID = c.FanID
			Inner join SLC_Report.dbo.Fan f 
				on c.FanID = f.ID
			Inner join Relational.CINList cl
				on f.SourceUID = cl.CIN
			Where 
				cg.RetailerID = @PartnerID
				and cg.StartDate <= @CycleEndDate
				and (cg.EndDate >= @EndDate or cg.EndDate is null) -- @EndDate is actually the cycle/half cycle start date
		END
	END
	ELSE 
	BEGIN -- Load source control group members for retailers requiring standard setup
		Insert into #Customers (FanID, CINID, RowNo)
		Select
			cg.FanID
			, cg.CINID
			, ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
		From Warehouse.Segmentation.ROC_Shopper_Segment_CtrlGroup as cg
		Left join Relational.Customer as c
			on cg.FanID = c.FanID
		Where	
			c.FanID is null -- Out of programme
			and cg.StartDate <= @EndDate
			and (cg.EndDate is null or cg.EndDate > @EndDate);
	END

	--Add Indexes

	Create Clustered Index i_Customer_CINID on #Customers (CINID);
	Create NonClustered Index i_Customer_FanID on #Customers (FanID);
	Create NonClustered Index i_Customer_RowNo on #Customers (RowNo);

	-- Create ConsumerCombination Table

	Set @BrandID = (Select BrandID from Staging.Partners_IncFuture Where PartnerID = @PartnerID);
	
	IF @BrandID IS NULL
		THROW 50002
			,  'Ensure partner is in Warehouse.Staging.Partners_IncFuture table'
			, 1
	

	IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs;

	Select
		ConsumerCombinationID 
	Into #CCIDs
	From Relational.ConsumerCombination as cc
	Where
		BrandID = @BrandID;

	--Add Indexes

	Create Clustered Index i_CCID_CCID on #CCIDs (ConsumerCombinationID);

	--Setup for retrieving customer transactions

	Declare
		@RowNo int
		, @RowNoMax int
		, @Acquire int
		--, @AcquirePct int
		, @Lapsed int
		, @Shopper int
		, @ChunkSize int;

	Set @RowNo = 1;
	Set @RowNoMax = (Select Max(RowNo) from #Customers);
	Set @ChunkSize = 250000;

	Select	@Acquire = Acquire -- Member is Acquire if their last spend was more than this number of months before the cycle start date
		,	@Lapsed = Lapsed -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
		,	@Shopper = Shopper -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
	From Segmentation.ROC_Shopper_Segment_Partner_Settings
	Where PartnerID = @PartnerID
	and StartDate <= @Today
	and (EndDate > @Today or EndDate is null);

	IF OBJECT_ID ('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders;
	
	Create Table #Spenders 
		(FanID int not null
		, CINID int not null
		, LatestTran Date
		, Spend Money
		, Lapsed bit
		, Prime bit not null
		, Segment Smallint not null
		, Primary Key (CINID)
		)

	-- Load customer transactions summary and decide which customers are Lapsed
	
	Declare
		@LDate Date = (Select Dateadd(month,-(@Lapsed),Dateadd(day,DATEDIFF(dd, 0,@EndDate)-2,0))) -- Aprox. today minus @Lapsed months
		, @ADate Date = (Select Dateadd(month,-(@Acquire),Dateadd(day,DATEDIFF(dd, 0, @EndDate)-2,0))) -- Aprox. today minus @Acquire months
		, @EDate Date = (Select Dateadd(day,DATEDIFF(dd, 0, @EndDate)-3,0));

	While @RowNo <= @RowNoMax
	Begin
	
		Insert Into #Spenders (FanID, CINID, LatestTran, Spend, Lapsed, Prime, Segment)
		Select
			Max(c.FanID) AS FanID
			, c.CINID			
			, Max(TranDate) as LatestTran
			, Sum(Amount) as Spend
			, Case
				When Max(TranDate) < @LDate Then 1
				Else
					Case when Max(TranDate) < Dateadd(month,-(@Shopper),Dateadd(day,DATEDIFF(dd, 0,@EndDate)-2,0)) Then 0 Else null End -- Added by Jason 01/06/2018: Aprox. today minus @Shopper months
			End as Lapsed
			, 0 as Prime
			, 0 as Segment
		From #CCIDs CCs
		Inner join Relational.ConsumerTransaction ct
			on CCs.ConsumerCombinationID = ct.ConsumerCombinationID
		Inner join #Customers c
			on	ct.CINID = c.CINID
			and c.RowNo between @RowNo and @RowNo + (@Chunksize-1) 
		Where
			TranDate Between @ADate and @EDate
			And not exists (Select NULL from #Spenders x where c.CINID = x.CINID)
		Group By
			c.CINID
		Having
			Sum(Amount) > 0;

		Set @RowNo = @RowNo+@ChunkSize;

	End

	-- Decide the prime member split points: lower spend customers have priority for being assigned to control groups

	Declare 
		@PrimeLap int
		, @PrimeExist int
		, @LapsedAmount money
		, @ExistingAmount money;

	Set @PrimeLap = (Select Count(*) as Rows from #Spenders Where Lapsed = 1)/3;
	Set @PrimeExist = (Select Count(*) as Rows from #Spenders Where Lapsed = 0)/3;

	IF OBJECT_ID ('tempdb..#Lapsed') IS NOT NULL DROP TABLE #Lapsed;
	
	Select Top (@PrimeLap)
		Spend 
	Into #Lapsed
	From #Spenders as s
	Where
		Lapsed = 1
	Order by
		s.Spend Desc;

	Set @LapsedAmount = (Select Min(Spend) From #Lapsed);

	IF OBJECT_ID ('tempdb..#Existing') IS NOT NULL DROP TABLE #Existing;
	
	Select Top (@PrimeExist)
		Spend 
	Into #Existing
	From #Spenders as s
	Where
		Lapsed = 0
	Order
		by s.Spend Desc;

	Set @ExistingAmount = (Select Min(Spend) From #Existing);

	--Update Spenders with split points

	Update #Spenders
	Set	Prime =	
		(Case
			When Lapsed = 1 and Spend >= @LapsedAmount then 1
			When Lapsed = 0 and Spend >= @ExistingAmount then 1
			Else 0
		End)
	, Segment =	
		(Case
			When Lapsed = 1 and Spend >= @LapsedAmount then 4 -- Lapsed
			When Lapsed = 1 then 3 -- Lapsed
			When Lapsed = 0 and Spend >= @ExistingAmount then 6 -- Shopper
			Else 5 -- Shopper
		End)
	Where Lapsed is not null;

	/***********************************************************************************************
	Identify Acquisition control members
	***********************************************************************************************/
	
	IF OBJECT_ID ('tempdb..#Acquisition') IS NOT NULL DROP TABLE #Acquisition;

	Select
		c.FanID
		, c.CINID
		, 2 as Segment -- Acquisition
	Into #Acquisition
	From #Customers as c
	Left join #Spenders s
		ON c.FanID = s.FanID
	Where
		s.FanID is null

	Declare @Rows int;

	Set @Rows = (Select Count(*)/2 From #Acquisition);

	Update #Acquisition
	Set Segment = 1 -- Acquisition
	Where FanID in 
	( 
		SELECT TOP (@Rows) FanID
		FROM #Acquisition 
		ORDER BY NewID() 
	);

	/***********************************************************************************************
	Load control members, along with segment types
	***********************************************************************************************/

	Declare @Qry nvarchar(max);

	Set @Qry =
	'If object_id('''+@TName+''') is not null drop table '+@TName+';
	'+'Select FanID, CINID,
			'+Cast(@PartnerID as Varchar(5))+' as PartnerID,
			Segment as SegmentID
	Into '+@TName+'
	From #Spenders
	Where Lapsed is not null
	Union All
	Select FanID, CINID,
			'+Cast(@PartnerID as Varchar(5))+' as PartnerID,
			Segment as SegmentID
	From #Acquisition';

	Exec sp_executeSQL @Qry;

	/***********************************************************************************************
	Write Entry to Joblog_Temp and update Joblog
	***********************************************************************************************/

	Set @EndTime = Getdate();

	UPDATE Staging.JobLog_Temp
	Set	
		EndDate = @EndTime
	Where
		StoredProcedureName = 'ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro' 
		AND TableSchemaName = 'Segmentation'
		AND TableName = @TableName
		AND EndDate IS NULL;

	Insert into Staging.JobLog
	Select
		StoredProcedureName
		, TableSchemaName
		, TableName
		, StartDate
		, EndDate
		, TableRowCount
		, AppendReload
	From Staging.JobLog_Temp;

	Truncate table Staging.JobLog_Temp;

END



