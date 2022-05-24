-- =============================================
-- Author:		<Shaun Hide>
-- Create date: <18th May 2017>
-- Description:	<I got tired of doing this every time so wanted to automate it>
-- =============================================
CREATE PROCEDURE [Prototype].[SegmentAssignment]
	-- Add the parameters for the stored procedure here
	(@BrandID int
	,@PopulationTable varchar(100)
	,@EndDate Date)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-----------------------------------------------------------------------------------------
	-- Create shopper table
	If Object_ID('tempdb..#Population') IS NOT NULL DROP TABLE #Population
	CREATE TABLE #Population
		(
			CINID int
		)

	EXEC('	INSERT INTO #Population
				Select	distinct CINID
				From	' + @PopulationTable + '
		 ')	

	CREATE CLUSTERED INDEX ix_CINID ON #Population(CINID)

	-----------------------------------------------------------------------------------------
	-- Find the ALS Lengths

	If Object_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	Select	distinct br.BrandName
			,br.BrandID
			,coalesce(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) as AcquireL
			,coalesce(mrf.SS_LapsersDefinition,blk.LapserL,lk.LapserL,br.LapserL0) as LapserL
			,br.SectorID
	Into	#Settings
	From	(
				Select	distinct BrandID
						,BrandName
						,SectorID
						,case when BrandName in ('Tesco','Asda','Sainsburys','Morrisons') then 3 end as AcquireL0
						,case when BrandName in ('Tesco','Asda','Sainsburys','Morrisons') then 1 end as LapserL0
				From	Warehouse.Relational.Brand
			) br
	Left Join	Warehouse.Relational.Partner p on p.BrandID = br.BrandID
	Left Join	Warehouse.Relational.MRF_ShopperSegmentDetails mrf on mrf.PartnerID = p.PartnerID
	Left Join	Warehouse.Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk on br.BrandID = blk.BrandID
	Left Join	Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on br.SectorID = lk.SectorID
	Where		coalesce(mrf.SS_AcquireLength,blk.acquireL,lk.AcquireL,br.AcquireL0) is not null
			and	br.BrandID = @BrandID

	DECLARE @LapsedDate DATE = (SELECT DATEADD(MONTH,-MIN(LapserL),@EndDate) FROM #Settings)
	DECLARE @AcquireDate DATE = (SELECT DATEADD(MONTH,-MIN(AcquireL),@EndDate) FROM #Settings)
	RAISERROR('Found ALS Lengths',0,1) WITH NOWAIT

	-----------------------------------------------------------------------------------------
	-- Find the ConsumerCombinationIDs
	If Object_ID('tempdb..#ConsumerCombinations') IS NOT NULL DROP TABLE #ConsumerCombinations
	Select	BrandID
			,ConsumerCombinationID
	Into	#ConsumerCombinations
	From	Warehouse.Relational.ConsumerCombination with (nolock)
	Where	BrandID = @BrandID
	--	and IsUKSpend = 1

	CREATE CLUSTERED INDEX ix_ConsumerCombinationID ON #ConsumerCombinations(BrandID,ConsumerCombinationID)

	RAISERROR('Found ConsumerCombinationsIDs',0,1) WITH NOWAIT

	-----------------------------------------------------------------------------------------
	-- Segment Assignment
	Select		a.CINID
				,case
					when @LapsedDate <= LastDate then 'Shopper'
					when @AcquireDate <= LastDate then 'Lapsed'
					else 'Acquire'
				 end as ShopperSegment
				,b.LastDate
	From		#Population a
	Left Join	(
					Select		pop.CINID
								,max(ct.TranDate) as LastDate
					From		#Population pop
					Join		Warehouse.Relational.ConsumerTransaction ct with (nolock) on pop.CINID = ct.CINID
					Join		#ConsumerCombinations cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID 
					Where		IsRefund = 0
							and	@AcquireDate < ct.TranDate and ct.TranDate <= @EndDate
					Group By	pop.CINID
				) b on a.CINID = b.CINID

	RAISERROR('Assigned Segments',0,1) WITH NOWAIT
END