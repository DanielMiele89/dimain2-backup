-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 22/06/2017
-- Description:	Script to update RBS Shopper segmets, based on the output of the natural sales SP that contains customer numbers by segment
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_RBS_ShopperSegmentSplits_Calculate](@BrandID INT) 
	
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('Tempdb..#WorkingBrands') IS NOT NULL DROP TABLE #WorkingBrands
	CREATE TABLE #WorkingBrands
	(ID Int Identity(1,1) primary key clustered,
	BrandID Int)
	
	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandID IS NULL
	BEGIN
		
		INSERT INTO #WorkingBrands (BrandID)
		SELECT	BrandID
		FROM	Warehouse.ExcelQuery.ROCEFT_BrandList
		
		-- Append current ROCEFT_ShopperSegments to the archive table, and truncate the ROCEFT_ShopperSegments table
		INSERT INTO Warehouse.InsightArchive.ROCEFT_ShopperSegments_Backup
		SELECT	*
		FROM	Warehouse.ExcelQuery.ROCEFT_ShopperSegments

		TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_ShopperSegments

		--  Append ShopperSegmentSplit data to the archive and clear down the table
		INSERT INTO Warehouse.InsightArchive.ROCEFT_ShopperSegmentSplit_Archive
		SELECT		CAST(GETDATE() as date) as BackupDate,
					*
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegmentSplit
		
		TRUNCATE TABLE  Warehouse.ExcelQuery.ROCEFT_ShopperSegmentSplit
		
	
	END
	ELSE
	BEGIN
		INSERT INTO #WorkingBrands (BrandID)
		VALUES (@BrandID)

		DELETE FROM	Warehouse.ExcelQuery.ROCEFT_ShopperSegmentSplit WHERE BrandID = @BrandID
		DELETE FROM Warehouse.ExcelQuery.ROCEFT_ShopperSegments WHERE BrandID = @BrandID

	END

	
	--  Insert data into the ROCEFT_ShopperSegments table as the working table
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_ShopperSegments
	SELECT  CycleIDRef,
			a.BrandID,
			Segment,
			Shopper_Segment,
			Cardholders
	FROM	Warehouse.ExcelQuery.ROCEFT_NaturalSpend a
	INNER JOIN #WorkingBrands b on a.BrandId = b.BrandID

	
		IF OBJECT_ID('Tempdb..#ShopperSegmentPerc') IS NOT NULL DROP TABLE #ShopperSegmentPerc
		SELECT		distinct BrandID,
					Segment,
					Shopper_Segment,
					sum(Cardholders*1.0) over(Partition by  BrandID, Shopper_Segment)/Sum(Cardholders) OVER (Partition by  BrandID) as SegmentPercentage
		INTO		#ShopperSegmentPerc
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegments
		UNION		
		SELECT		Distinct BrandID,
					Segment,
					'Universal' as Shopper_Segment,
					1.00 as SegmentPercentage
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegments
		UNION		
		SELECT		Distinct BrandID,
					Segment,
					'Launch' as Shopper_Segment,
					1.00 as SegmentPercentage
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegments
		UNION		
		SELECT		Distinct BrandID,
					Segment,
					'Birthday' as Shopper_Segment,
					1.00/12 as SegmentPercentage
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegments
		UNION		
		SELECT		Distinct BrandID,
					Segment,
					'Homemover' as Shopper_Segment,
					0.009675 as SegmentPercentage
		FROM		Warehouse.ExcelQuery.ROCEFT_ShopperSegments

		

		INSERT INTO Warehouse.ExcelQuery.ROCEFT_ShopperSegmentSplit
		SELECT		*
		FROM		#ShopperSegmentPerc
    
END