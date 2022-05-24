
-- =============================================
-- Author:		JEA
-- Create date: 09/10/2012
-- Description:	Retrieves sample narratives for a given brand ID
-- =============================================
CREATE PROCEDURE [gas].[Brand_FetchSampleNarratives] 
	(
		@BrandID SMALLINT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT DISTINCT TOP 10 c.Narrative
    FROM Staging.Combination C
    INNER JOIN Relational.BrandMID B on C.BrandMIDID = B.BrandMIDID
    WHERE B.BrandID = @BrandID
    ORDER BY Narrative
    
END

