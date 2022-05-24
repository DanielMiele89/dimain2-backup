

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- =============================================
-- Author:		YA
-- Create date: 29/10/2012
-- Description:	Retrieves a list of brands
-- =============================================
CREATE PROCEDURE [gas].[Brand_GetAll]
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		CAST(BrandID AS INT) AS BrandID
	,	BrandName     
	,	IsLivePartner      
	FROM Relational.Brand
	ORDER BY BrandName
	
   
END


