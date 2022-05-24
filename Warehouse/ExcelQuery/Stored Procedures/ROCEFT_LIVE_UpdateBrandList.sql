
-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Add a single brand to the ROC Forecast Brand Table
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_UpdateBrandList]
	@BrandList VARCHAR(500)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM Warehouse.ExcelQuery.ROCEFT_BrandList
	WHERE	CHARINDEX(',' + CAST(BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0
	
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_BrandList
		SELECT		DISTINCT a.BrandID,
					a.BrandName,
					'NA' AS Core,
					0 AS Margin,
					0.35 AS Override,
					CASE WHEN p.BrandID IS NULL THEN 0 ELSE 1 END AS IsPartner
		FROM		Warehouse.Relational.Brand a
		LEFT JOIN	Warehouse.Relational.Partner b on a.BrandID = b.BrandID
		LEFT JOIN	(	SELECT  DISTINCT BrandID
						FROM   Warehouse.Relational.Partner
						WHERE BrandID IS NOT NULL
						UNION
						SELECT  DISTINCT br.BrandID
						FROM	nFI.Relational.Partner p
						JOIN	Warehouse.Staging.Partners_Vs_Brands pvb
							ON	p.PartnerID = pvb.PartnerID
						JOIN    Warehouse.Relational.Brand      br
							ON  pvb.BrandID = br.BrandID
					) p
					ON	a.BrandID = p.BrandID
		WHERE		CHARINDEX(',' + CAST(a.BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

END