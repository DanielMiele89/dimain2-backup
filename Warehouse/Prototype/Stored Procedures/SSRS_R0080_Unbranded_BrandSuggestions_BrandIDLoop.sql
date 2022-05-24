

-- *****************************************************************************************************
-- Author: Ijaz Amjad
-- Create date: 18/03/2016
-- Description: IN-PROGRESS
-- *****************************************************************************************************
CREATE PROCEDURE [Prototype].[SSRS_R0080_Unbranded_BrandSuggestions_BrandIDLoop](
			@BrandIDs INT)
									
AS

	SET NOCOUNT ON;


----------------------------------------------------------------------------------------
-----------------------------Generate List of Top Brands--------------------------------
----------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#B') IS NOT NULL DROP TABLE #B
SELECT	TOP (@BrandIDs) a.BrandID,
	ROW_NUMBER() OVER(ORDER BY a.SpendThisYear DESC) AS RowNo
INTO #B
FROM [Warehouse].[MI].[TotalBrandSpend] as a
INNER JOIN Warehouse.relational.Brand as b
       on a.BrandID = b.BrandID

--Select * FROM #B

----------------------------------------------------------------------------------------
---------------Call Per Brand Stored Procedure - looping for all brands-----------------
----------------------------------------------------------------------------------------
DECLARE	@RowNo INT,
	@MaxRowNo INT,
	@BrandID INT

SET @RowNo = 1
SET @MaxRowNo = @BrandIDs
--SELECT @RowNo,@MaxRowNo

TRUNCATE TABLE [Prototype].[SSRS_R0080_Unbranded_BrandSuggestions]

WHILE @RowNo <= @MaxRowNo
BEGIN
	SET	@BrandID = (Select BrandID from #B where RowNo = @RowNo)
	EXEC	[Prototype].[SSRS_R0080_Unbranded_BrandSuggestions_SingleBrand] @BrandID
	SET	@RowNo = @RowNo+1
	--SELECT @RowNo
	--SELECT @RowNo, @BrandID
END