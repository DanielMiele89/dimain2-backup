-- =============================================
-- Author:		Shaun H
-- Create date: 01/02/2019
-- Description:	Determine Segment Lengths for Each Brand
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_RetailerSegmentationLengths_Calculate]
	@BrandList VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;

	IF OBJECT_ID('Tempdb..#AllBrands') IS NOT NULL DROP TABLE #AllBrands
	CREATE TABLE #AllBrands
		(
			ID INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
			BrandID INT
		)

	--  "IF" statement to deal with a refresh of a single brand or all brands
	IF @BrandList IS NULL
	BEGIN			
		INSERT INTO #AllBrands (BrandID)
			SELECT	BrandID
			FROM	Warehouse.ExcelQuery.ROCEFT_BrandList

		TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Segment_Lengths
	END
	ELSE
	BEGIN
		INSERT INTO #AllBrands (BrandID)
			SELECT	BrandID
			FROM	Warehouse.Relational.Brand br
			WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

		DELETE FROM Warehouse.ExcelQuery.ROCEFT_Segment_Lengths
		WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
	END

	IF OBJECT_ID('tempdb..#Settings') IS NOT NULL DROP TABLE #Settings
	SELECT	br.BrandName
			,br.BrandID
			,COALESCE(part.Acquire,blk.acquireL,lk.AcquireL,12) as AcquireL
			,COALESCE(part.Lapsed,blk.LapserL,lk.LapserL,6) as LapserL
			,br.SectorID
	INTO	#Settings
	FROM	Warehouse.Relational.Brand br
	LEFT JOIN	
		(		SELECT	DISTINCT p.BrandID,
						part.Acquire,
						part.Lapsed
				FROM	Warehouse.Relational.Partner p
				JOIN	Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings part
					ON	p.PartnerID = part.PartnerID
				WHERE	EndDate IS NULL
		) part
		ON	br.BrandID = part.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_BrandSegmentLengthOverride blk 
			on	br.BrandID = blk.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_SectorSegmentLengthOverride lk 
			on	br.SectorID = lk.SectorID
	JOIN	#AllBrands a
		ON	br.BrandID = a.BrandID

	UPDATE s
	SET	AcquireL = 60
	FROM #Settings s
	WHERE 60 < AcquireL

	-- Commit
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_Segment_Lengths
		SELECT	*
		FROM	#Settings

	-- Segment Settings
	UPDATE	bl
	SET		bl.Margin = CAST((CAST(AcquireL AS VARCHAR(10)) + '.' + CAST(LapserL AS VARCHAR(10)) + '9') AS FLOAT)
	FROM	Warehouse.ExcelQuery.ROCEFT_BrandList bl
	JOIN	#Settings s
		ON	bl.BrandID = s.BrandID
END