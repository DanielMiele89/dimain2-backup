
/******************************************************************************
Author: Jason Shipp
Created: 12/04/2018
Purpose:
	- Segment control group members into ALS groups and sub-groups, using bespoke rules defined by Sainsburys

------------------------------------------------------------------------------
Modification History

******************************************************************************/

CREATE PROCEDURE Segmentation.ROC_Shopper_Segmentation_Sainsburys_Bespoke
	(@PartnerNo int = 4708
	, @EnDate Date 
	, @TName varchar(200)
	)

WITH EXECUTE AS OWNER

AS
BEGIN

	SET NOCOUNT ON;
	
	---- For testing
	--DECLARE @PartnerNo int = 4708
	--DECLARE @EnDate Date = '2018-03-01'
	--DECLARE @TName varchar(200) = 'Sandbox.jason.Control470820180301' 

	Declare
		@PartnerID int
		, @BrandID int
		, @Today datetime
		, @time DATETIME
		, @msg VARCHAR(2048)
		, @TableName varchar(50)
		, @EndTime datetime
		, @EndDate Date = @EnDate;

	Set @Today = getdate();
	Set @PartnerID = @PartnerNo;
	Set @TableName = 'Roc_Shopper_Segment_Members - '+Cast(@PartnerID as Varchar(5));

	/***********************************************************************************************
	Identify Shopper and Lapsed control members 
	***********************************************************************************************/

	-- Create Customer Table

	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers;

	Select	
		cg.FanID
		, cg.CINID
		, ROW_NUMBER() OVER(ORDER BY c.FanID DESC) AS RowNo
	Into #Customers
	From Segmentation.ROC_Shopper_Segment_CtrlGroup cg
	Left join Relational.Customer c
		on cg.FanID = c.FanID
	Where
		c.FanID is null -- Out of programme
		and cg.StartDate <= @EndDate
		and (cg.EndDate is null or cg.EndDate > @EndDate);

	-- Add Indexes

	Create Clustered Index i_Customer_CINID on #Customers (CINID);
	Create NonClustered Index i_Customer_FanID on #Customers (FanID);
	Create NonClustered Index i_Customer_RowNo on #Customers (RowNo);
	
	-- Create ConsumerCombination Table

	Set @BrandID = (Select distinct BrandID from Warehouse.Relational.[Partner] Where PartnerID = @PartnerID);

	IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs;

	Select
		ConsumerCombinationID 
	Into #CCIDs
	From Relational.ConsumerCombination cc
	Where
		BrandID = @BrandID;

	--Add Indexes

	Create Clustered Index i_CCID_CCID on #CCIDs (ConsumerCombinationID);

	/***********************************************************************************************
	Load control members, along with segment types
	***********************************************************************************************/

	-- Assign Shopper spend periods to control members
	
	If Object_ID('tempdb..#SpendPeriod') IS NOT NULL DROP TABLE #SpendPeriod;

	WITH LastOnlineTran AS
		(Select	
			ct.CINID
			, Sum(ct.Amount) AS Spend
			, Max(case when 0 < ct.Amount then 1 else 0 end) as MainBrand_spender_ever
			, Max(case when TranDate > '2016-01-27' then 1 else 0 end) as MainBrand_spender_24M
			, Max(case when	TranDate > '2017-07-26' then 1 else 0 end) as MainBrand_spender_06M
		From Warehouse.Relational.ConsumerTransaction ct with (nolock)
		Inner join #CCIDs cc
			on cc.ConsumerCombinationID = ct.ConsumerCombinationID
		Where 
			0 < ct.Amount
			and isonline = 1
			and TranDate <= '2018-01-26'
		Group by
			ct.CINID
		)
	Select	
		cl.CINID
		, cl.fanid
		, Spend
		, MainBrand_spender_ever 
		, MainBrand_spender_24M
		, MainBrand_spender_06M
	Into #SpendPeriod
	From #Customers cl
	Left Join LastOnlineTran b
		on cl.CINID = b.CINID;

	-- Assign Shopper segments to control members

	If Object_ID('tempdb..#Control_Seg') is not null drop table #Control_Seg;

	Select
		s.FanID
		, @PartnerID AS PartnerID
		, s.Spend
		, Case 
			when MainBrand_spender_ever is null then 'A' -- Never spent online before assigned as Acquire
			when MainBrand_spender_ever = 1 and MainBrand_spender_24M = 0 then 'L' -- Last spent online more than 24 months ago assigned as Lapsed
			when MainBrand_spender_06M = 0 and MainBrand_spender_24M = 1 then 'S' -- Last spent online in last 6-24 months assigned as Shopper
			Else NULL
		End as SegmentName
	Into #Control_Seg
	From #SpendPeriod s
	Where
		MainBrand_spender_ever is null 
		or ( 
			MainBrand_spender_ever = 1 and
			MainBrand_spender_24M = 0
		) 
		or (
			MainBrand_spender_06M = 0 and
			MainBrand_spender_24M = 1
		);

	-- Assign split points to define ALS-sub groups (higher assigned IDs = high spenders)

	If Object_ID('tempdb..#Control_Sub_Seg_Split') is not null drop table #Control_Sub_Seg_Split;

	Select 
		s.FanID
		, s.PartnerID
		, s.SegmentName
		, NTILE(2) OVER (Partition by s.SegmentName ORDER BY s.Spend ASC) as SplitNum
	Into #Control_Sub_Seg_Split
	From #Control_Seg s
	Where SegmentName = 'A'
	
	Union all

	Select 
		s.FanID
		, s.PartnerID
		, s.SegmentName
		, NTILE(3) OVER (Partition by s.SegmentName ORDER BY s.Spend ASC) as SplitNum
	From #Control_Seg s
	Where SegmentName = 'L'

	Union all 

	Select 
		s.FanID
		, s.PartnerID
		, s.SegmentName
		, NTILE(3) OVER (Partition by s.SegmentName ORDER BY s.Spend ASC) as SplitNum
	From #Control_Seg s
	Where SegmentName = 'S'

	-- Load final control customer segments

	Declare @Qry nvarchar(max);

	Set @Qry =
	'If Object_ID ('''+@TName+''') is not null drop table '+@TName+';
	Select
		s.FanID
		, '+Cast(@PartnerID as Varchar(5))+' as PartnerID
		, Case 
			When s.SegmentName = ''A'' and SplitNum = 1 then 1 -- Low spend Acquire
			When s.SegmentName = ''A'' and SplitNum > 1 then 2 -- High spend Acquire
			When s.SegmentName = ''L'' and SplitNum = 1 then 3 -- Low spend Lapsed
			When s.SegmentName = ''L'' and SplitNum > 1 then 4 -- High spend Lapsed
			When s.SegmentName = ''S'' and SplitNum = 1 then 5 -- Low spend Shopper
			When s.SegmentName = ''S'' and SplitNum > 1 then 6 -- High spend shopper
			Else null
		End as SegmentID
	Into '+@TName+'
	From #Control_Sub_Seg_Split s;'

	Exec sp_executeSQL @Qry;

END