-- =============================================
-- Author:		JEA
-- Create date: 28/09/2012
-- Description:	Retrieves Brands for the MIDI brand lookup
-- =============================================
CREATE PROCEDURE [GAS].[Brand_Fetch] 
	(
		@BrandID SmallInt
	)
AS
BEGIN
	
	SET NOCOUNT ON;
-- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
    SELECT CAST(BrandID AS INT) AS BrandID, CAST(BrandID AS INT) AS Id, BrandName, IsLivePartner, IsHighRisk
    FROM Relational.Brand
    WHERE BrandID = @BrandID
    
END
