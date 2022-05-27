
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

CREATE PROCEDURE [Segmentation].[ControlGroupSegmentation_Virgin] (	@PartnerID INT
																,	@EnDate DATE
																,	@TName VARCHAR(200))

WITH EXECUTE AS OWNER

AS
BEGIN

	SET NOCOUNT ON
	--SET TRANSACTION LEVEL UNCOMMITTED

	/*
	Execution	TableName
EXEC Warehouse.Segmentation.ControlGroupSegmentation_Virgin 4117, '2021-01-28','Sandbox.Rory.VirginControl411720210128'	Sandbox.Rory.VirginControl4117202101288
*/

	-- For testing

	--DECLARE @PartnerID int = 3421
	--DECLARE @EnDate Date = '2021-02-25'
	--DECLARE @TName varchar(200) = 'Sandbox.Rory.VirginControl342120210225'	



	Declare 
		@PID int
		, @BrandID int
		, @Today datetime
		, @time datetime
		, @msg varchar(2048)
		, @TableName varchar(50)
		, @EndTime datetime
		, @EndDate date = @EnDate

	Set	@Today = getdate();
	Set	@PID = @PartnerID;
	Set @TableName = 'Roc_Shopper_Segment_Members - '+Cast(@PID as Varchar(5));
	
	/******************************************************************************
	Write Entry to Joblog_Temp
	******************************************************************************/

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

	IF @PID IN ( -- Fetch RetailerIDs and associated PartnerIDs for retailers requiring bespoke setup (in programme)
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
		IF @PID IN ( -- Check in programme members table contains members for the retailer for Iron Offers overlapping the cycle
			SELECT DISTINCT s.PartnerID 
			FROM Warehouse.Relational.IronOfferSegment s
			INNER JOIN [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ip 
			ON s.IronOfferID = ip.IronOfferID
			WHERE 
			(s.RetailerID = @PID) -- @PID should by the primary PartnerID
			AND s.OfferStartDate <= @CycleEndDate
			--AND (s.OfferEndDate >= @EndDate OR s.OfferEndDate IS NULL) -- @EndDate is actually the cycle/half cycle start date
			AND CAST(ip.StartDate AS date) <= @CycleEndDate
			--AND (CAST(ip.EndDate AS date) >= @EndDate OR ip.EndDate IS NULL)
		)
		BEGIN -- Load source control group members for retailers requiring bespoke setup
			With IronOfferIDs AS (
				Select IronOfferID from Warehouse.Relational.IronOfferSegment s
				Where 
				(s.RetailerID = @PID OR s.PartnerID = @PID)
				AND s.OfferStartDate <= @CycleEndDate
				--AND (s.OfferEndDate >= @EndDate OR s.OfferEndDate IS NULL) -- @EndDate is actually the cycle/half cycle start date
			)
			Insert into #Customers (FanID, CINID, RowNo)
			Select 
			x.FanID
			, x.CINID
			, ROW_NUMBER() OVER(ORDER BY x.FanID DESC) AS RowNo
			From (
					Select	Distinct
							cg.FanID
						,	cl.CINID
					From [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] cg
					Inner join [WH_Virgin].[Derived].[Customer] c -- Make sure in programme
						on cg.FanID = c.FanID
					Inner join [SLC_Report].[dbo].[Fan] f 
						on c.FanID = f.ID
					Inner join [WH_Virgin].[Derived].[CINList] cl
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
				cg.RetailerID = @PID
				and cg.StartDate <= @CycleEndDate
				and (cg.EndDate >= @EndDate or cg.EndDate is null) -- @EndDate is actually the cycle/half cycle start date
		END
	END
	ELSE 
	BEGIN -- Load source control group members for retailers requiring standard setup
		Insert into #Customers (FanID, CINID, RowNo)
		Select	DISTINCT
				cg.FanID
			,	cg.CINID
			,	ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
		From Warehouse.Segmentation.ROC_Shopper_Segment_CtrlGroup as cg
		Left join Relational.Customer as c
			on cg.FanID = c.FanID
		Where	
			c.FanID is null -- Out of programme
			and cg.StartDate <= @EndDate
			AND cg.FanID != 16228277
			and (cg.EndDate is null or cg.EndDate > @EndDate);
	END

	--Add Indexes

	Create UNIQUE Clustered Index i_Customer_CINID on #Customers (CINID);
	Create NonClustered Index i_Customer_FanID on #Customers (FanID);
	Create NonClustered Index i_Customer_RowNo on #Customers (RowNo);


	-- Create ConsumerCombination Table

	Set @BrandID = (Select BrandID from Staging.Partners_IncFuture Where PartnerID = @PID);
	
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

	Create UNIQUE Clustered Index i_CCID_CCID on #CCIDs (ConsumerCombinationID);

	--Setup for retrieving customer transactions

	Declare
		@RowNo int
		, @RowNoMax int
		, @Acquire int
		, @Lapsed int
		, @Shopper int;

	Select	@Acquire = Acquire -- Member is Acquire if their last spend was more than this number of months before the cycle start date
		,	@Lapsed = Lapsed -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
		,	@Shopper = Shopper -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
	From Segmentation.ROC_Shopper_Segment_Partner_Settings
	Where PartnerID = @PID
	and StartDate <= @Today
	and (EndDate > @Today or EndDate is null);


	-- Load customer transactions summary and decide which customers are Lapsed
	
		Declare	@LDate Date = (Select Dateadd(month,-(@Lapsed),Dateadd(day,DATEDIFF(dd, 0,@EndDate)-2,0))) -- Aprox. today minus @Lapsed months
			,	@ADate Date = (Select Dateadd(month,-(@Acquire),Dateadd(day,DATEDIFF(dd, 0, @EndDate)-2,0))) -- Aprox. today minus @Acquire months
			,	@EDate Date = (Select Dateadd(day,DATEDIFF(dd, 0, @EndDate)-3,0))
			,	@SDate Date = Dateadd(month,-(@Shopper),Dateadd(day,DATEDIFF(dd, 0,@EndDate)-2,0));

		IF OBJECT_ID ('tempdb..#CT') IS NOT NULL DROP TABLE #CT;
		SELECT	c.FanID
			,	c.CINID
			,	d.LatestTran
			,	d.Spend
		INTO #CT
		FROM (	SELECT	ct.CINID        
					,	LatestTran = Max(ct.TranDate)
					,	Spend = Sum(ct.Amount)
				FROM [Relational].[ConsumerTransaction] ct       				
				WHERE ct.TranDate BETWEEN @ADate AND @EDate
				AND EXISTS (	SELECT 1
								FROM #CCIDs CCs
								WHERE CCs.ConsumerCombinationID = ct.ConsumerCombinationID)				
				GROUP BY ct.CINID
				HAVING SUM(ct.Amount) > 0) d
		INNER JOIN (	SELECT	FanID = MAX(c.FanID)
							,	c.CINID
						FROM #Customers c
						GROUP BY c.CINID) c
			ON c.CINID = d.CINID
		
		OPTION (RECOMPILE);

		IF OBJECT_ID ('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders;
		Create Table #Spenders (FanID int null
							,	CINID int not null
							,	LatestTran Date
							,	Spend Money
							,	Lapsed bit
							,	Prime bit not null
							,	Segment Smallint not null)

		Insert Into #Spenders (FanID, CINID, LatestTran, Spend, Lapsed, Prime, Segment)
		SELECT	ct.FanID
			,	ct.CINID
			,	ct.LatestTran
			,	ct.Spend
			,	Lapsed = CASE
							WHEN ct.LatestTran < @LDate THEN 1
							WHEN ct.LatestTran < @SDate THEN 0
							ELSE null
						END -- Added by Jason 01/06/2018: Aprox. today minus @Shopper months
			,	0 as Prime
			,	0 as Segment
		FROM #CT ct
		WHERE ct.FanID IS NOT NULL
		
		CREATE CLUSTERED INDEX CIX_FanID ON #Spenders (FanID)
		CREATE NONCLUSTERED INDEX IX_LapsedSepnd ON #Spenders (Lapsed, Spend)

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
			'+Cast(@PID as Varchar(5))+' as PartnerID,
			Segment as SegmentID
	Into '+@TName+'
	From #Spenders
	Where Lapsed is not null
	Union All
	Select FanID, CINID,
			'+Cast(@PID as Varchar(5))+' as PartnerID,
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
		StoredProcedureName = 'ControlGroupSegmentation_Virgin' 
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



