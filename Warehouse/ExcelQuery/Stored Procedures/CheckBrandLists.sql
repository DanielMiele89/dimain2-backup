-- =============================================
-- Author:		Shaun Hide
-- Create date: 10th July 2018
-- Description:	Check whether the brand(s) in question are in each of the main tools
-- =============================================
CREATE PROCEDURE ExcelQuery.CheckBrandLists
	@BrandList VARCHAR(500) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	IF OBJECT_ID('tempdb..#BrandList') IS NOT NULL DROP TABLE #BrandList
	CREATE TABLE #BrandList
		(
			BrandID INT,
			BrandName VARCHAR(50)
		)

	IF @BrandList IS NULL 
		BEGIN
			INSERT INTO #BrandList
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.Relational.Brand
		END
	ELSE
		BEGIN
			INSERT INTO #BrandList
				SELECT	BrandID,
						BrandName
				FROM	Warehouse.Relational.Brand
				WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
		END

	CREATE CLUSTERED INDEX cix_BrandID On #BrandList (BrandID)

	SELECT	br.BrandID,
			br.BrandName,
			CASE WHEN roc.BrandID IS NULL THEN 0 ELSE 1 END AS InROCTool,
			CASE WHEN amx.BrandID IS NULL THEN 0 ELSE 1 END AS InAMEXTool,
			CASE WHEN pep.BrandID IS NULL THEN 0 ELSE 1 END AS InPEPSTool,
			CASE WHEN svs.BrandID IS NULL THEN 0 ELSE 1 END AS InSalesVisSuite,
			CASE WHEN bcb.BrandID IS NULL THEN 0 ELSE 1 END AS InBrandCorrelationTool
	FROM	#BrandList br
	LEFT JOIN	Warehouse.ExcelQuery.ROCEFT_BrandList roc WITH (NOLOCK)
		ON	br.BrandID = roc.BrandID
	LEFT JOIN	Warehouse.Prototype.AMEX_BrandList amx WITH (NOLOCK)
		ON	br.BrandID = amx.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.MVP_BrandList pep WITH (NOLOCK)
		ON	br.BrandID = pep.BrandID
		AND	pep.EndDate IS NULL
	LEFT JOIN	Warehouse.ExcelQuery.SVSBrands svs WITH (NOLOCK)
		ON	br.BrandID = svs.BrandID
	LEFT JOIN	Warehouse.ExcelQuery.BrandCorrelationBrands bcb WITH (NOLOCK)
		On	br.BrandID = bcb.BrandID

END