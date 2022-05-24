-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Code to create the shopper segment lengths for each brand
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_RetailerSegmentationLengths_Calculate] (@BrandID INT)
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('Tempdb..#AllBrands') IS NOT NULL DROP TABLE #AllBrands
	CREATE TABLE #AllBrands
	(ID Int Identity(1,1) primary key clustered,
	BrandID Int)
	

	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
	BEGIN
			
		INSERT INTO #AllBrands (BrandID)
		SELECT	BrandID
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

		TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Segment_lengths
	END
	ELSE
	BEGIN
		INSERT INTO #AllBrands (BrandID)
		VALUES (@BrandID)

		DELETE FROM Warehouse.ExcelQuery.ROCEFT_Segment_lengths WHERE BrandID = @BrandID
	END

	DECLARE @NumBrands Int
	DECLARE @i int


	SET @i = 1
	SET @NumBrands = (SELECT Max(ID) from #AllBrands)

	WHILE @i <= @NumBrands
	BEGIN
				If Object_ID('tempdb..#Brand') IS NOT NULL DROP TABLE #Brand
				Select              br.BrandID
									,br.BrandName
									,p.PartnerID
									,p.PartnerName
				Into                #Brand
				From				Relational.Brand br
				Left Join			Relational.Partner p on br.BrandID = p.BrandID
				Where               br.BrandID = (SELECT a.Brandid from #AllBrands a WHERE ID = @i)


				-- select * from #Brand

				------------------------------------------
				-- a) Find the Acquire and Lapsed Length
				------------------------------------------

				If Object_ID('tempdb..#MasterRetailerFile') IS NOT NULL DROP TABLE #MasterRetailerFile
				Select		br.BrandID
							,br.BrandName
							,mrf.[SS_AcquireLength] as SS_AcquireLength
							,mrf.[SS_LapsersDefinition] as SS_LapsersDefinition
							,coalesce(mrf.[SS_WelcomeEmail],1) as SS_WelcomeEmail
							,cast(coalesce(SS_Acq_Split,1)*100 as int) as Acquire_Pct
				Into        #MasterRetailerFile 
				From		Relational.MRF_ShopperSegmentDetails mrf
				Join        Relational.Partner p on  mrf.PartnerID = p.PartnerID
				RIGHT Join  #Brand br on p.BrandID = br.BrandID


				INSERT INTO Warehouse.ExcelQuery.ROCEFT_Segment_lengths
					Select		distinct a.BrandName
								,a.BrandID
								,coalesce(part.Acquire,mrf.SS_AcquireLength,blk.acquireL,a.AcquireL0,12) as AcquireL
								,coalesce(part.Lapsed,mrf.SS_LapsersDefinition,blk.LapserL,a.LapserL0,6) as LapserL
								,a.sectorID
					From     (Select	b.BrandID
										,b.BrandName
										,b.sectorID
										,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 3 else lk.acquireL end as AcquireL0
										,case when b.BrandName in ('Tesco', 'Asda','Sainsburys','Morrisons') then 1 else lk.LapserL end as LapserL0
										,lk.Acquire_Pct as Acquire_Pct0
								From		Relational.Brand b
								Join		#Brand br on  b.BrandID = br.BrandID
								Left Join   Warehouse.Prototype.ROCP2_SegFore_SectorTimeFrame_LK lk on lk.sectorid=b.sectorID
							   ) a
					Left Join	Prototype.ROCP2_SegFore_BrandTimeFrame_LK blk  on           blk.brandid=a.brandID
					Left Join   #MasterRetailerFile mrf on           mrf.BrandID = a.BrandID
					Left Join	Warehouse.Relational.Partner p
						ON		a.BrandID = p.BrandID
					Left Join	Segmentation.ROC_Shopper_Segment_Partner_Settings part
						ON		p.PartnerID = part.PartnerID
					Where		coalesce(part.Acquire,mrf.SS_AcquireLength,blk.acquireL,AcquireL0) is not null

				SET @i = @i+1
	END



END