-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Add a single brand to the ROC Forecast Brand Table
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_UpdateBrandList](@BrandID INT)
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM Warehouse.ExcelQuery.ROCEFT_BrandList WHERE BrandID = @BrandID
	
	INSERT INTO Warehouse.ExcelQuery.ROCEFT_BrandList

	SELECT		a.BrandID,
				a.BrandName,
				CASE WHEN c.Core IS NULL THEN 'NA' ELSE c.core END as Core,
				CASE WHEN c.Margin IS NULL THEN 0 ELSE c.Margin END AS Margin,
				CASE WHEN c.Override_Pct_of_CBP IS NULL THEN 0 ELSE c.Override_Pct_of_CBP END AS Override,
				CASE WHEN p.BrandID IS NULL THEN 0 ELSE 1 END AS IsPartner
	FROM		Warehouse.relational.Brand a
	LEFT JOIN	Warehouse.Relational.partner b on a.BrandID = b.BrandID
	LEFT JOIN	Warehouse.Relational.Master_Retailer_Table c on c.PartnerID = b.PartnerID
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
	WHERE		a.BrandID = @BrandID



END