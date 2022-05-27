
/******************************************************************************
Author:	Jason Shipp
Created: 09/09/2019
Purpose: 
	- Segments MFDD control group universe based on members' most recent spend at the given retailer OINs in the Archive_Light.dbo.CBP_DirectDebit_TransactionHistory table
	- Segmented members loaded into a new table
	- Normal member source: Warehouse.Segmentation.ROC_Shopper_Segment_CtrlGroup
	- Bespoke member source: [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram]

------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD] (
		@PartnerNo int,
		@EnDate Date,
		@TName varchar(200)
		)

WITH EXECUTE AS OWNER

AS
BEGIN

	IF @PartnerNo NOT IN (SELECT PartnerID FROM Warehouse.Segmentation.PartnerSettings_DD)
	BEGIN
	PRINT 'This is a CLO partner: segment using Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro instead'
	RETURN -1 -- Exit stored procedure if CLO partner
	END

	---- For testing
	--DECLARE @PartnerNo int = 4846
	--DECLARE @EnDate Date = '2021-01-28'
	--DECLARE @TName varchar(200) = 'Sandbox.Rory.Control484620210128'

	Declare 
		@PartnerID int
		, @BrandID int
		, @Today datetime
		, @time datetime
		, @msg varchar(2048)
		, @TableName varchar(50)
		, @EndTime datetime
		, @EndDate date = @EnDate;

	Set	@Today = getdate();
	Set	@PartnerID = @PartnerNo;
	Set @TableName = 'Roc_Shopper_Segment_Members - '+Cast(@PartnerID as Varchar(5));
	
	/******************************************************************************
	Write Entry to Joblog_Temp
	******************************************************************************/
	
	Insert into Staging.JobLog_Temp
	Select
		StoredProcedureName = 'ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD'
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
	Load PartnerIDs
	***********************************************************************************************/

	IF OBJECT_ID('tempdb..#PartnerIDs') IS NOT NULL DROP TABLE #PartnerIDs;

	SELECT @PartnerID AS PartnerID -- Should be the primary PartnerID
	INTO #PartnerIDs

	UNION

	SELECT -- Alternate PartnerIDs
	PartnerID
	FROM Warehouse.APW.PartnerAlternate 
	WHERE AlternatePartnerID = @PartnerID

	UNION 

	SELECT 
	PartnerID
	FROM nFI.APW.PartnerAlternate 
	WHERE AlternatePartnerID = @PartnerID;

	CREATE CLUSTERED INDEX CIX_PartnerIDs ON #PartnerIDs (PartnerID);

	/***********************************************************************************************
	Create DirectDebitOriginatorID table
	***********************************************************************************************/

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC;

	SELECT	cc.ConsumerCombinationID_DD
	INTO #CC
	FROM Warehouse.Relational.ConsumerCombination_DD cc
	WHERE EXISTS (	SELECT 1
					FROM [Relational].[Partner] pa
					INNER JOIN #PartnerIDs p
						ON pa.PartnerID = p.PartnerID
					WHERE cc.BrandID = pa.BrandID);

	CREATE UNIQUE CLUSTERED INDEX CIX_DDSuppliers ON #CC (ConsumerCombinationID_DD);

	/******************************************************************************
	Load transaction data from Archive_Light.dbo.CBP_DirectDebit_TransactionHistory into a temp table for more efficient querying for the control groups
	******************************************************************************/

	IF OBJECT_ID('tempdb..#TransactionHistoryData') IS NOT NULL DROP TABLE #TransactionHistoryData;
	SELECT	ct.FanID
		,	ct.TranDate
		,	ct.Amount
	INTO #TransactionHistoryData
	FROM [Relational].[ConsumerTransaction_DD] ct
	WHERE EXISTS (	SELECT 1
					FROM #CC cc
					WHERE ct.ConsumerCombinationID_DD = cc.ConsumerCombinationID_DD)

	CREATE NONCLUSTERED INDEX IX_TransactionHistoryData ON #TransactionHistoryData (FanID, TranDate) INCLUDE (Amount);

	
	/***********************************************************************************************
	Identify Shopper and Lapsed control members 
	***********************************************************************************************/
	
	-- Load Customer Table

	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;

	CREATE TABLE #Customers (
		FanID int
		, CINID int
		, RowNo int
	);

	IF @PartnerID IN ( -- Fetch RetailerIDs and associated PartnerIDs for retailers requiring bespoke setup
		SELECT PartnerID FROM ( 
			SELECT r.RetailerID AS PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			UNION 
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			INNER JOIN Warehouse.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
			UNION
			SELECT pa.PartnerID FROM Warehouse.Staging.ControlSetup_BespokeControlGroupRetailers r
			INNER JOIN nFI.APW.PartnerAlternate pa ON r.RetailerID = pa.AlternatePartnerID
		) x
		WHERE 
			x.PartnerID IN (  -- Check in programme members table contains members for the retailer for Iron Offers overlapping the cycle
				SELECT DISTINCT s.PartnerID 
				FROM Warehouse.Relational.IronOfferSegment s
				INNER JOIN [WH_AllPublishers].[Selections].[ControlGroupMembers_InProgram] ip
				ON s.IronOfferID = ip.IronOfferID
				WHERE 
				(s.RetailerID = @PartnerID OR s.PartnerID = @PartnerID)
				AND s.OfferStartDate <= @CycleEndDate
				--AND (s.OfferEndDate >= @EndDate OR s.OfferEndDate IS NULL) -- @EndDate is actually the cycle/half cycle start date
				AND CAST(ip.StartDate AS date) <= @CycleEndDate
				--AND (CAST(ip.EndDate AS date) >= @EndDate OR ip.EndDate IS NULL)
			)
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
	BEGIN -- Load source control group members for retailers requiring standard setup
		Insert into #Customers (FanID, CINID, RowNo)
		Select
			cg.FanID
			, cg.CINID
			, ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
		From Warehouse.Segmentation.ROC_Shopper_Segment_CtrlGroup cg
		Left join Relational.Customer c
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

	--Setup for retrieving customer transactions

	Declare
		 @Acquire int
		, @Lapsed int
		, @Shopper int;

	Set @Acquire = ( -- Member is Acquire if their last spend was more than this number of months before the cycle start date
		Select
			Acquire 
		From Segmentation.PartnerSettings_DD
		Where
			PartnerID = @PartnerID
			and StartDate <= @Today and
			(EndDate > @Today or EndDate is null)
	);
	
	Set @Lapsed = ( -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
		Select
			Lapsed
		From Segmentation.PartnerSettings_DD
		Where
			PartnerID = @PartnerID
			and StartDate <= @Today
			and (EndDate > @Today or EndDate is null)
	);

	Set @Shopper = ( -- Member is Lapsed if their last spend was more than this number of months before the cycle start date
		Select
			Shopper
		From Segmentation.PartnerSettings_DD
		Where
			PartnerID = @PartnerID
			and StartDate <= @Today
			and (EndDate > @Today or EndDate is null)
	);

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

	Insert Into #Spenders (FanID, CINID, LatestTran, Spend, Lapsed, Prime, Segment)
	Select
		Max(c.FanID) AS FanID
		, c.CINID			
		, Max(TranDate) as LatestTran
		, Sum(Amount) as Spend
		, Case
			When Max(TranDate) < @LDate Then 1
			Else
				Case when Max(TranDate) < Dateadd(month,-(@Shopper),Dateadd(day,DATEDIFF(dd, 0,@EndDate)-2,0)) Then 0 Else null End
		End as Lapsed
		, 0 as Prime
		, 0 as Segment
	From #TransactionHistoryData dd
	INNER JOIN #Customers c
		ON dd.FanID = c.FanID
	WHERE 
		TranDate Between @ADate and @EDate
	Group By
			c.CINID
		Having
			Sum(Amount) > 0;
			
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
		StoredProcedureName = 'ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD' 
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