-- =============================================
-- Author:		Beyers Geldenhuys
-- Create date: 20/06/2017
-- Description:	Add a single brand to the ROC Forecast Brand Table
-- Additions:   Added a Relational Partner Flag to highlight certain parts of the forecast
-- Issues:		We still have a historic duplication issue of brands where they have more than one partnerID on Partner table
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_UpdateBrandList_v2]
	(
		@BrandID INT
	)
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
					CASE WHEN b.PartnerID IS NOT NULL THEN 1 ELSE 0 END AS RelationalPartnerFlag
		FROM		Warehouse.Relational.Brand a
		LEFT JOIN	Warehouse.Relational.Partner b on a.BrandID = b.BrandID
		LEFT JOIN	Warehouse.Relational.Master_Retailer_Table c on c.PartnerID = b.PartnerID
		WHERE		a.BrandID = @BrandID

END
