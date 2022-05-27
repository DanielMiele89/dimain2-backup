-- =============================================
-- Author:		Shaun
-- Create date: 23/09/2016
-- Description:	Test ODODC Connection with Excel
-- =============================================
CREATE PROCEDURE Prototype.SH_ExcelTest 
	-- Add the parameters for the stored procedure here
	(
	@IndividualBrand SMALLINT,
	@IndividualBrand_2 SMALLINT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM Warehouse.Relational.Brand
	WHERE BrandID = @IndividualBrand or BrandID = @IndividualBrand_2
END
