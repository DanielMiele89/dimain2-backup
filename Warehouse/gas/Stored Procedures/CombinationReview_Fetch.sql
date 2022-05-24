CREATE PROCEDURE [gas].[CombinationReview_Fetch] 
      
AS
BEGIN
      
      SET NOCOUNT ON;
	-- Returned Id as well to generate entity class with IAuditable interface & [AuditIdentifier] attribute from complex type.
    SELECT cr.ID AS CombinationReviewID, cr.ID, cr.MID, cr.Narrative, '' AS LocationAddress, cr.LocationCountry
            , m.MCC, m.MCCDesc, CAST(cr.SuggestedBrandID AS INT) AS SuggestedBrandID
            , b.BrandName, crc.Confidence, crc.MatchType, f.MIDFrequency, cr.IsHighVariance
            , b.IsLivePartner, b.IsHighRisk
			, cr.OriginatorID
			, a.AcquirerName AS Acquirer
			, mccS.SectorName AS MCCSector
			, bs.SectorName AS BrandSector
			, cr.BrandProbability AS Probability
			, cr.MatchCount AS SuggestedMatches
      FROM Staging.CTLoad_MIDINewCombo cr
      INNER JOIN Staging.CTLoad_BrandSuggestConfidence crc ON cr.MatchType = crc.Confidence
      LEFT OUTER JOIN Relational.Brand b on cr.SuggestedBrandID = b.BrandID
      LEFT OUTER JOIN Relational.MCCList m ON cr.MCCID = m.MCC
	  INNER JOIN Relational.Acquirer a ON cr.AcquirerID = a.AcquirerID
	  INNER JOIN Relational.BrandSector mccS ON M.SectorID = mccS.SectorID
	  LEFT OUTER JOIN Relational.BrandSector bs ON M.SectorID = bs.SectorID
      INNER JOIN (SELECT MID, LocationCountry, OriginatorID, COUNT(1) AS MIDFrequency
                        FROM Staging.CTLoad_MIDINewCombo
                        GROUP BY MID, LocationCountry, OriginatorID) f 
							ON cr.MID = f.MID AND cr.LocationCountry = f.LocationCountry AND cr.OriginatorID = f.OriginatorID
      ORDER BY Narrative
    
END

select * from Staging.CTLoad_BrandSuggestConfidence