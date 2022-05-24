﻿
/********************************************************************************************
** Name: [Segmentation].[ROC_Shopper_Segmentation_Individual_Partner_V2] 
** Desc: Segmentation of customers per partner 
** Auth: Zoe Taylor
** Date: 10/02/2017
*********************************************************************************************
** Change History
** ---------------------
** #No		Date		Author			Description 
** --		--------	-------			------------------------------------
** 1    
*********************************************************************************************/

CREATE Procedure [Prototype].[OOP_Segmentation] 
	(@PartnerNo int
	,@DateToBeSeg date
	,@ControlGroupID int)

AS

Declare @PartnerID int,
		@BrandID int,
	    @Today datetime,
		@time DATETIME,
		@msg VARCHAR(2048),
		@TableName varchar(50), 
		@StartDate date,
		@RowCount int,
		@ErrorCode INT, 
		@ErrorMessage NVARCHAR(MAX), 
		@ShopperCount int = 0, 
		@LapsedCount int = 0, 
		@AcquireCount int = 0, 
		@Acquire INT, 
		@Lapsed INT,
		@SPName varchar(100)


Set		@Today = @DateToBeSeg
Set		@StartDate = Dateadd(day,DATEDIFF(dd, 0, @Today)-0,0)
Set		@PartnerID = @PartnerNo

Set @Acquire =	(
					Select	Acquire 
					From	Segmentation.ROC_Shopper_Segment_Partner_Settings 
					Where	PartnerID = @PartnerID
				)

Set @Lapsed =	( 
					Select	Lapsed 
					From	Segmentation.ROC_Shopper_Segment_Partner_Settings 
					Where	PartnerID = @PartnerID
				)

set @SPName =	''
set @SPName =	(select cast(OBJECT_SCHEMA_NAME(@@PROCID) + '.' + OBJECT_NAME(@@PROCID) as varchar(100)))
		

/******************************************************************
		
		Spenders  

******************************************************************/

	-------------------------------------------------------------------
	--		Get customer details
	-------------------------------------------------------------------

	IF OBJECT_ID ('tempdb..#Customers') IS NOT NULL DROP TABLE #Customers
	CREATE TABLE #Customers
		(
			FanID int
			,CINID int
			,RowNo int
		)

	INSERT INTO #Customers
		EXEC('
				Select		cg.FanID
							,cin.CINID
							,ROW_NUMBER() OVER(ORDER BY cin.CINID DESC) AS RowNo
				From		Warehouse.Relational.ControlGroupMembers cg
				Join		SLC_Report.dbo.Fan f on cg.FanID = f.ID
				Left Join	Warehouse.Relational.CINList cin on f.SourceUID = cin.CIN
				Where		cg.ControlGroupID = ' + @ControlGroupID + '
			')

	SELECT @msg = 'Customers Collected'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT


	-------------------------------------------------------------------
	--		Create indexes
	-------------------------------------------------------------------
	
	Create Clustered Index i_Customer_CINID on #Customers (CINID)
	Create NonClustered Index i_Customer_FanID on #Customers (FanID)
	Create NonClustered Index i_Customer_RowNo on #Customers (RowNo)

	Set @BrandID = (Select BrandID from [Staging].[Partners_IncFuture] as p Where PartnerID = @PartnerID)

	-------------------------------------------------------------------
	--		Create ConsumerCombination table
	-------------------------------------------------------------------
	
	IF OBJECT_ID ('tempdb..#CCIDs') IS NOT NULL DROP TABLE #CCIDs
	Select	ConsumerCombinationID 
	Into	#CCIDs
	From	Relational.ConsumerCombination as cc  with (Nolock)
	Where	BrandID = @BrandID

	-------------------------------------------------------------------
	--		Add Indexes
	-------------------------------------------------------------------

	Create Clustered Index i_CCID_CCID on #CCIDs (ConsumerCombinationID)

	SELECT @msg = 'Consumer Combination IDs assigned'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Set up for retrieving customer transactions at merchant
	-------------------------------------------------------------------

	Declare @RowNo int, 
			@RowNoMax int,
			@ChunkSize int,
			@LapsedDate Date,
			@AcquireDate Date,
			@ShopperDate Date

	Set @RowNo = 1
	Set @RowNoMax = (Select Max(RowNo) from #Customers)
	Set @ChunkSize = 250000
	Set @LapsedDate = Dateadd(month,-(@Lapsed),Dateadd(day,DATEDIFF(dd, 0, @Today)-2,0))
	Set @AcquireDate = Dateadd(month,-(@Acquire),Dateadd(day,DATEDIFF(dd, 0, @Today)-2,0))
	Set @ShopperDate = Dateadd(day,DATEDIFF(dd, 0, @Today)-3,0)

	IF OBJECT_ID ('tempdb..#Spenders') IS NOT NULL DROP TABLE #Spenders
	Create Table #Spenders 
			(
				FanID int not null
				,CINID int not null
				,LatestTran Date
				,Spend Money
				,Lapsed bit not null
				,Segment Smallint not null
				,Primary Key (FanID)
			)

	SELECT @msg = 'Created Empty Spenders Table'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------
	--		Get transactions
	-------------------------------------------------------------------

	While @RowNo <= @RowNoMax
	Begin
	
		Insert Into #Spenders
			Select	*,
					Case When Lapsed = 1 then 8
						 When Lapsed = 0 then 9
						 Else NULL 
					End
			From 
			(Select	c.FanID,
					c.CINID,
					Max(TranDate)	as LatestTran,
					Sum(Amount)		as Spend,
					Case
						When Max(TranDate) < @LapsedDate then 1
						Else 0
					End as Lapsed
			From #CCIDs as CCs
			inner join Relational.ConsumerTransaction as ct with (Nolock)
				on CCs.ConsumerCombinationID = ct.ConsumerCombinationID
			inner join #Customers as c
				on	ct.CINID = c.CINID and
					c.RowNo between @RowNo and @RowNo + (@Chunksize-1) 
			Where TranDate Between @AcquireDate and @ShopperDate
			Group By c.CINID,c.FanID
				Having Sum(Amount) > 0 
			) as a
			OPTION	(RECOMPILE) 
		
		Set @RowNo = @RowNo+@ChunkSize

		SELECT @msg = 'Added customers '+Cast(@RowNo as varchar(10))+ 
					  ' to ' + Cast(@RowNo+(@ChunkSize-1) as varchar(10)) +' to Spenders Table'
		EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT
	End

	IF OBJECT_ID('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
	Select	c.FanID
			,c.CINID
			,CASE
				WHEN s.Segment IS NULL THEN 7
				ELSE s.Segment
			 END AS Segment
	Into	#AllCustomers
	From	#Customers c
	Left Join #Spenders s 
		on	c.FanID = s.FanID 
		and c.CINID = s.CINID

	CREATE CLUSTERED INDEX ix_FanID ON #AllCustomers(FanID)

/******************************************************************
		
		Acquire 

******************************************************************/
	
	-------------------------------------------------------------------
	--		Get heatmap scores
	-------------------------------------------------------------------	

	--IF OBJECT_ID ('tempdb..#AllCustomers') IS NOT NULL DROP TABLE #AllCustomers
	--Select	FanID,
	--		MarketableByEmail,
	--		Coalesce(AgeCurrent,0) as AgeCurrent,
	--		Coalesce(Gender,'U') as Gender,
	--		Coalesce([CAMEO_CODE_GROUP],'99') as CameoGroupCode
	--Into	#AllCustomers
	--From	Relational.Customer as c with (nolock)
	--Left Outer join [Relational].[CAMEO] as a with (nolock)
	--	on c.Postcode = a.Postcode
	--Where CurrentlyActive = 1

	--Create Clustered Index cix_AllCustomers_FanID on #AllCustomers (FanID)

	--SELECT @msg = 'Created #AllCustomers Table'
	--EXEC Staging.oo_TimerMessage @msg, @time OUTPUT


	--IF OBJECT_ID ('tempdb..#HeatMaps') IS NOT NULL DROP TABLE #HeatMaps
	--Select	Case
	--			When UnknownGroup = 1 then 100 
	--			Else a.Index_RR
	--		End as Index_RR,
	--		b.Gender,
	--		Left(Age_Group,2) as AgeGroup,
	--		Left(Cameo_Grp,2) as CameoGroup
	--Into #HeatMaps
	--from InsightArchive.SalesSTO_HeatmapBrandCombo_Index as a with (nolock)
	--inner join InsightArchive.HM_Combo_SalesSTO_Tool as b with (nolock)
	--	on a.ComboID_2 = b.ComboID
	--Where BrandID = @BrandID

	--SELECT @msg = 'Created #Heatmap Table'
	--EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	---------------------------------------------------------------------
	----		Assign segment to customers
	---------------------------------------------------------------------
	
	--IF OBJECT_ID ('tempdb..#AllCustomers_HeatMap') IS NOT NULL DROP TABLE #AllCustomers_HeatMap
	--Select	a.*,
	--		Coalesce(Index_RR,100) as Index_RR,
	--		0 as Prime,
	--		7 as Segment
	--Into #AllCustomers_HeatMap
	--from #AllCustomers as a
	--left outer join Segmentation.Roc_Shopper_Segment_AgeBands as b with (nolock)
	--	on a.AgeCurrent Between b.StartInt and b.Endint
	--Left Outer join #HeatMaps as hm
	--	on	a.CameoGroupCode = hm.CameoGroup and
	--		a.Gender = hm.gender and
	--		Left(b.Age_Group,2) = hm.AgeGroup
	--Left Outer join #Spenders as s
	--	on	a.FanID = s.FanID
	--Where	s.FanID is null

	--SELECT @msg = 'Created #AllCustomers_HeatMap Table'
	--EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

	--Create Clustered Index cix_AllCustomers_HeatMap on #AllCustomers_HeatMap (FanID)


/******************************************************************
		
		Update segment tables 

******************************************************************/
	
	-------------------------------------------------------------------
	--		Update spenders
	-------------------------------------------------------------------
	
	Update c
	SET c.EndDate = DATEADD(day, -1, @StartDate)
	From #AllCustomers as s
	INNER JOIN [Warehouse].[Prototype].[CT_ALS_Splits_ControlGroup] as c
		on	s.FanID = c.FanID and
			c.PartnerID = @PartnerID and
			s.Segment <> c.ShopperSegmentTypeID and
			c.EndDate IS NULL

	Insert into [Warehouse].[Prototype].[CT_ALS_Splits_ControlGroup]
	Select s.FanID, @PartnerID, s.Segment, @StartDate, NULL
	From #AllCustomers as s
	left Outer join [Warehouse].[Prototype].[CT_ALS_Splits_ControlGroup] as c
		on	s.FanID = c.FanID and
			c.PartnerID = @PartnerID and
			s.Segment = c.ShopperSegmentTypeID and
			c.EndDate IS NULL
	Where c.FanID is null