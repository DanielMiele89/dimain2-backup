CREATE PROCEDURE [GAS].[Brand_FetchByNameStart]
	@NameStartsWith VARCHAR(50)
AS

SET NOCOUNT ON

-- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
SELECT 
	CAST(BrandID AS INT) AS [BrandId]
,	CAST(BrandID AS INT) AS [Id]	
,	BrandName
,	IsLivePartner	
,	IsHighRisk
FROM Relational.Brand
WHERE BrandName Like @NameStartsWith + '%'