-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <10/04/2017>
-- Description:	<Heatmap Index table (needed for RBS ranking)>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_Heatmap]
AS
BEGIN
	SET NOCOUNT ON;
	-------------------------------------------------------------------------------------

	Declare @time DATETIME
	Declare @msg VARCHAR(2048)

	SELECT @msg = 'Start'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	--				Assign a random selection of shoppers to ComboIDs 
	-------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#cins') IS NOT NULL DROP TABLE #cins
	Select	distinct c.FanID
		,cl.CINID
		,c.Gender
		,ROW_NUMBER() over (order by newID()) as randrow
		,CASE	
			WHEN c.AgeCurrent < 18 OR c.AgeCurrent IS NULL THEN '99. Unknown'
			WHEN c.AgeCurrent BETWEEN 18 AND 24 THEN '01. 18 to 24'
			WHEN c.AgeCurrent BETWEEN 25 AND 29 THEN '02. 25 to 29'
			WHEN c.AgeCurrent BETWEEN 30 AND 39 THEN '03. 30 to 39'
			WHEN c.AgeCurrent BETWEEN 40 AND 49 THEN '04. 40 to 49'
			WHEN c.AgeCurrent BETWEEN 50 AND 59 THEN '05. 50 to 59'
			WHEN c.AgeCurrent BETWEEN 60 AND 64 THEN '06. 60 to 64'
			WHEN c.AgeCurrent >= 65 THEN '07. 65+' 
			END AS Age_Group
		,coalesce(c.region,'Unknown') as Region
		,isnull((cam.[CAMEO_CODE_GROUP] +'-'+ camg.CAMEO_CODE_GROUP_Category),'99. Unknown') as CAMEO_CODE_GRP
		,MarketableByEmail
	Into	#cins
	From	Warehouse.Relational.Customer c with (nolock) 
	Join	Warehouse.Relational.CINList cl with (nolock) on c.SourceUID = cl.CIN
	Left Join	Warehouse.Relational.CAMEO cam with (nolock)  on cam.postcode = c.postcode
	Left Join	Warehouse.Relational.cameo_code_group camG with (nolock)  on camG.CAMEO_CODE_GROUP =cam.CAMEO_CODE_GROUP
	Left Join	Warehouse.Staging.Customer_DuplicateSourceUID dup with (nolock)  on dup.sourceUID = c.SourceUID 
	Where	dup.sourceuid  is NULL
		and CurrentlyActive=1 and MarketableByEmail=1

	CREATE INDEX ix_CINID on #cins(CINID)

	IF OBJECT_ID('tempdb..#cins_rand') IS NOT NULL DROP TABLE #cins_rand
	Select	cinid
	Into	#cins_rand
	From	#cins
	Where	randrow <= 1500000   

	CREATE INDEX ix_CINID on #cins_rand(CINID)

	IF OBJECT_ID('tempdb..#CIN_ComboID') IS NOT NULL DROP TABLE #CIN_ComboID
	Select		a.CINID
				,lk2.comboID as ComboID_2 
	Into		#CIN_ComboID
	From		#cins_rand a
	Left Join	#cins d on d.CINID=a.CINID
	Left Join	Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2
			on	d.gender=lk2.gender 
			and d.CAMEO_CODE_GRP=lk2.CAMEO_grp 
			and d.Age_Group=lk2.Age_Group

	CREATE INDEX ix_CINID on #CIN_ComboID(CINID);

	SELECT @msg = 'ComboID Assignment Complete'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	-------------------------------------------------------------------------------------
	-- Checks

	Declare		@RowCount int
	Set			@RowCount = (select count(1) from #CIN_ComboID) 

	Declare		@DistCount int
	Set			@DistCount = (select count(distinct CINID) from #CIN_ComboID)

	Declare		@ComboIDCount int
	Set			@ComboIDCount = (select sum(case when comboID_2 is not null then 1 else 0 end) from	#CIN_ComboID)

	Declare		@DistinctComboID int
	Set			@DistinctComboID = (select count(distinct comboID_2) from #CIN_ComboID)

	Print 'Total Rows: ' + cast(@RowCount as varchar(10))
	Print 'Distinct CINID: ' + cast(@DistCount as varchar(10))
	Print 'CINIDs with ComboID: ' + cast(@ComboIDCount as varchar(10))
	Print 'Distinct ComboID Count: ' + cast(@DistinctComboID as varchar(10))

	-------------------------------------------------------------------------------------
	--			Loop through each brand in the ROCEFT_BrandList table		 
	-------------------------------------------------------------------------------------
	SELECT @msg = 'Loop Starting'
	EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

	DECLARE @brandid int, @rowno int
	Set @rowno=1

	WHILE @rowno  <= (select max(rowno) from Warehouse.ExcelQuery.ROCEFT_RefreshBrand)     
	BEGIN
		---------------------------------------------------------------------------------------------
		-- Create a single brand brand table
		IF OBJECT_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
		Select	*
		Into	#Brand
		From	Warehouse.ExcelQuery.ROCEFT_RefreshBrand
		Where	RowNo = @RowNo

		Set @BrandID = (select brandid from #Brand where rowno=@rowno)
		Print 'Row Number: ' + cast(@rowno as varchar(10))
		Print 'BrandID: ' + cast(@BrandID as varchar(10))

		/*	Defines refresh logic
			- If it is a single brand addition, always refresh brand
			- Else, if it doesnt exist, add, otherwise dont add anything
		*/
		Declare @RunHeatmap Bit
		IF	(Select max(rowno) from Warehouse.ExcelQuery.ROCEFT_RefreshBrand) = 1 
			BEGIN
				Set @RunHeatmap = 1
			END
		ElSE
			IF (Select distinct BrandID From Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index where BrandID = @BrandID) IS NULL
				BEGIN
					Set @RunHeatmap = 1
				END
			ELSE
				BEGIN 
					Set @RunHeatmap = 0
				END

		-- Run the heatmap refresh
		IF @RunHeatmap = 1
			BEGIN
				---------------------------------------------------------------------------------------------
				-- Identify the relevant consumer combination IDs
		
				If Object_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc
				Select	cc.brandid
						,ConsumerCombinationID
				Into	#cc
				From	Relational.ConsumerCombination cc
				Join	#Brand br on br.BrandID=cc.BrandID
				Where	cc.IsUKSpend = 1

				CREATE CLUSTERED INDEX ix_ComboID on #CC(BrandID,ConsumerCombinationID)

				------------------------------------------------------------
				-- Historic Spend (12m) allowing for 2 week lag in data feed
	
				If Object_ID('tempdb..#HistoricData12m') IS NOT NULL DROP TABLE #HistoricData12m
				Select	ct.CINID
						,sum(Amount) as Spend
						,count(1)	 as Trans
				Into	#HistoricData12m
				From	Warehouse.Relational.ConsumerTransaction ct with (nolock)
				Join	#CIN_ComboID cin on ct.CINID = cin.CINID
				Join	#cc cc on ct.ConsumerCombinationID = cc.ConsumerCombinationID
				Where	IsRefund = 0
					and ct.TranDate between DATEADD(Month,-12,DATEADD(Day,-13,GETDATE())) and DATEADD(Day,-14,GETDATE())
				Group by ct.CINID

				CREATE CLUSTERED INDEX ix_CINID on #HistoricData12m(CINID)

				-- select * from #HistoricData12m

				------------------------------------------------------------
				-- Complete heatmap index for this brand
	
				If Object_ID('tempdb..#Heatmap_1') IS NOT NULL DROP TABLE #Heatmap_1
					Select a.*
						   ,b.Spend
						   ,b.Trans
						   ,case when b.spend is not null then
							   1
							else
							   0
							end as Spender
					   Into	#Heatmap_1
					   From	#CIN_ComboID a
				  Left Join	#HistoricData12m b 
						 on	a.CINID = b.CINID

				If Object_ID('tempdb..#Heatmap_ComboScore') IS NOT NULL DROP TABLE #Heatmap_ComboScore
				Select	ComboID_2
						,coalesce(sum(Spender),0)	as Combo_Spenders
						,coalesce(sum(Trans),0)		as Combo_Trans
						,coalesce(sum(Spend),0)		as Combo_Spend
						,count(distinct CINID)		as Combo_GroupVol
				Into	#Heatmap_ComboScore
				From	#Heatmap_1
				Group by ComboID_2

				If Object_ID('tempdb..#Heatmap_Base') IS NOT NULL DROP TABLE #Heatmap_Base
				Select	coalesce(sum(Spender),0)	as Base_Spenders
						,coalesce(sum(Trans),0)		as Base_Trans
						,coalesce(sum(Spend),0)		as Base_Spend
						,count(distinct CINID)		as Base_GroupVol
				Into	#Heatmap_Base
				From	#Heatmap_1

				IF Object_ID('tempdb..#HM_Combo_Index') IS NOT NULL DROP TABLE #HM_Combo_Index
				select		* 
							,@brandid as brandid
							,case when Combo_GroupVol>=1 then Combo_Spenders/ cast(Combo_GroupVol as real) else NULL end as RR_Combo
							,case when Base_GroupVol>=1 then Base_Spenders/ cast(Base_GroupVol as real) else NULL end  as RR_Base
							,case when Base_Spenders>=1 then (Combo_Spenders/ cast(Combo_GroupVol as real)) / (Base_Spenders/ cast(Base_GroupVol as real)) * 100 else NULL end as Index_RR
							,case when Combo_GroupVol>=1 then Combo_Spend/ cast(Combo_GroupVol as real) else NULL end as SPC_Combo
							,case when Base_GroupVol>=1 then Base_Spend/ cast(Base_GroupVol as real) else NULL end  as SPC_Base
							,case when Base_Spenders>=1 then (Combo_Spend/ cast(Combo_GroupVol as real)) / (Base_Spend/ cast(Base_GroupVol as real)) * 100 else NULL end as Index_SPC
				Into		#HM_Combo_Index
				From		#Heatmap_ComboScore com
				cross join	#Heatmap_Base

				-- Insert Output into a permanent table
				Insert Into Warehouse.ExcelQuery.ROCEFT_HeatmapBrandCombo_Index
					Select	@BrandID as BrandID
							,ComboID_2 as ComboID
							,Combo_Spenders
							,Combo_Spend
							,Combo_Trans as Combo_Volume
							,Base_Spenders
							,Base_Spend
							,Base_Trans as Base_Volume
							,RR_Combo
							,RR_Base
							,Index_RR
							,SPC_Base
							,SPC_Combo
							,Index_SPC
					From	#HM_Combo_Index

				OPTION (RECOMPILE)
			END

		SELECT @msg = 'Loop just finished ' + cast(@rowno as varchar(10)) + ', brand inserted = ' + cast(@RunHeatmap as varchar(1))
		EXEC Prototype.oo_TimerMessage @msg, @time OUTPUT

		Set @rowno = @rowno +1
	END
	-------------------------------------------------------------------------------------	
END
