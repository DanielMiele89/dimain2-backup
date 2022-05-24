
CREATE PROCEDURE [ExcelQuery].[ROCEFT_TEST_UpdateBrandList]
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
					COALESCE(ov.Override,0.35) AS Override,
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
		LEFT JOIN	(	SELECT	DISTINCT pvb.BrandID,
								nfi.Override
						FROM	Warehouse.Staging.Partners_Vs_Brands pvb
						JOIN	Warehouse.Relational.nFI_Partner_Deals nfi
							ON	pvb.PartnerID = nfi.PartnerID
						WHERE	EndDate IS NULL
							AND	ClubID IN (132,138)
					) ov
					ON	a.BrandID = ov.BrandID
		WHERE		CHARINDEX(',' + CAST(a.BrandID AS VARCHAR) + ',', ',' + @BrandList + ',') > 0

END