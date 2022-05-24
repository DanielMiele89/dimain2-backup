CREATE PROCEDURE [ExcelQuery].[TestingFramework_Popn_Shopper]		
	(@brandtable varchar(max)
	,@enddate varchar(10)
	,@CustNumber varchar(max))
AS
BEGIN
SET NOCOUNT ON	
	
	IF OBJECT_ID('tempdb..#Brands') IS NOT NULL DROP TABLE #Brands
	CREATE TABLE #Brands
		(
			BrandCount int
			,BrandID int
		)

	DECLARE @sql varchar(Max)
	SET @sql =	'SELECT	ROW_NUMBER() OVER(ORDER BY BrandID) AS BrandCount
						,BrandID
				 FROM ' + @brandtable +  ''

	INSERT INTO #Brands execute (@sql)

	IF OBJECT_ID('tempdb..#Output') IS NOT NULL DROP TABLE #Output
	CREATE TABLE #Output
		(
			BrandID int
			,ID int
		)

	Declare @j int, @i int
	Select @j = max(BrandCount) from #Brands
	Set @i = 1

	While @i <= @j 
		Begin
			Declare @BrandID varchar(max)
			Select  @BrandID = BrandID From #Brands Where BrandCount = @i
			Print	@BrandID

			IF OBJECT_ID('tempdb..#masterretailerfile') IS NOT NULL DROP TABLE #masterretailerfile

			Select		[BrandID]
						,[SS_AcquireLength]
						,[SS_LapsersDefinition]
						,[SS_WelcomeEmail]
						,cast([SS_Acq_Split]*100 as int) as Acquire_Pct
			Into        #masterretailerfile
			From        [Warehouse].[Relational].[MRF_ShopperSegmentDetails] a
			Inner Join  [Warehouse].[Relational].[Partner] p on a.PartnerID = p.PartnerID
			Where       BrandID = @BrandID

			IF OBJECT_ID('tempdb..#settings') IS NOT NULL DROP TABLE #settings

			SELECT DISTINCT		a.BrandID
								,coalesce(mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0) as AcquireL
								,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0) as LapserL
								,a.sectorID
								,COALESCE(mrf.Acquire_Pct,blk.Acquire_Pct,Acquire_Pct0) as Acquire_Pct
			INTO                #settings
			FROM	(
					SELECT			b.BrandID
									,b.sectorID
									,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
									,case when brandname in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
									,lk.Acquire_Pct as Acquire_Pct0
					FROM			[Warehouse].[Relational].[Brand] b  ---- corrected code here LG
					LEFT JOIN		[Warehouse].[Prototype].[ROCP2_SegFore_SectorTimeFrame_LK] lk on lk.sectorid=b.sectorID
					WHERE			b.BrandID = @BrandID
					) a
			LEFT JOIN			[Warehouse].[Prototype].[ROCP2_SegFore_BrandTimeFrame_LK] blk on blk.BrandID=a.BrandID
			LEFT JOIN			#masterretailerfile mrf on mrf.BrandID = a.BrandID
			WHERE				coalesce(mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null

			Declare           @Lapsed int
			Set               @Lapsed = (select LapserL * -1 from  #settings) 
			--Select			  @lapsed as Lapsed

			Declare           @Acquire int
			Set               @Acquire = (select AcquireL * -1 from #settings)  --- we can get these from a lookup table ROC model
			--Select			  @Acquire as Acquire

			IF OBJECT_ID('tempdb..#cc') IS NOT NULL DROP TABLE #cc

			Select	BrandID
					,consumercombinationid
			Into	#cc
			From	Relational.ConsumerCombination
			Where	BrandID=@BrandID

			CREATE CLUSTERED INDEX cc_consumercombinationid ON #cc(consumercombinationid)

			IF OBJECT_ID('tempdb..#customers') IS NOT NULL DROP TABLE #customers

			Select distinct cinid
			Into			#customers
			From			Relational.customer c
			Join			Relational.CINList cin on cin.CIN=c.SourceUID
			Left Join		Warehouse.Staging.Customer_DuplicateSourceUID dup on dup.sourceUID = c.SourceUID
			Where			dup.SourceUID IS NULL
			and				c.CurrentlyActive = 1
			and				c.MarketableByEmail = 1

			CREATE CLUSTERED INDEX c_cinid ON #customers(cinid)

			IF OBJECT_ID('tempdb..#spenders') IS NOT NULL DROP TABLE #spenders

			Select	ct.cinid
			Into	#spenders
			From	Relational.ConsumerTransaction ct 
			Join	#customers c on c.CINID = ct.CINID
			Join	#cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
			Where	trandate between DATEADD(MM,@Lapsed,@enddate) and @enddate

			CREATE CLUSTERED INDEX c_cinid ON #spenders(cinid)

			IF OBJECT_ID('tempdb..#Existing') IS NOT NULL DROP TABLE #Existing
			CREATE TABLE #Existing
				(
					ID Int
					,RandomID UniqueIdentifier
				)

			DECLARE @sql_1 varchar(Max)
			SET @sql_1 =	'
							Select distinct top ' + @CustNumber + ' 
								c.cinid as id, 
								newid() as randomID
							From #customers c
							Inner Join	#spenders s on c.CINID = s.CINID
							Order By	newid()
							'
			INSERT INTO #Existing execute (@sql_1)
			
			INSERT INTO	#Output
				SELECT	@BrandID as BrandID
						,ID
				FROM	#Existing

			Set @i = @i + 1
		End

		Select * 
		From #Output
		Order By BrandID
				,ID	
end