CREATE PROCEDURE [GAS].[Brand_FetchBySearchTerms] 
      (
            @BrandNameSearch Varchar(50),
            @NarrativeSearch Varchar(50)
      )
AS
BEGIN
      
      SET NOCOUNT ON;

      SET @BrandNameSearch = RTRIM(LTRIM(@BrandNameSearch))
      SET @NarrativeSearch = RTRIM(LTRIM(@NarrativeSearch))

      --Add wildcards if input strings are not blank
      IF @BrandNameSearch != ''
      BEGIN
      SET @BrandNameSearch = '%' + @BrandNameSearch + '%'
      END
      
      IF @NarrativeSearch != ''
      BEGIN
      SET @NarrativeSearch = @NarrativeSearch + '%'
      END

      --Brands that conform to the brand search
    SELECT CAST(BrandID AS INT) AS BrandID, CAST(BrandID AS INT) AS Id, BrandName, IsLivePartner, IsHighRisk
    FROM Relational.Brand
    WHERE BrandName LIKE @BrandNameSearch
    
    UNION
    
    --Brands that conform to the narrative search
    -- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
    SELECT CAST(b.BrandID AS INT) AS BrandID, CAST(b.BrandID AS INT) AS Id, b.BrandName, b.IsLivePartner, b.IsHighRisk
    FROM Relational.Brand b
    INNER JOIN Relational.BrandMID bm ON b.BrandID = bm.BrandID
    INNER JOIN Staging.Combination c ON bm.BrandMIDID = c.BrandMIDID
    WHERE C.Narrative LIKE @NarrativeSearch
    
    ORDER BY BrandName
    
END