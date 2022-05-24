-- =============================================
-- Author:		JEA
-- Create date: 11/03/2013
-- Description:	Parameter test sproc
-- =============================================
CREATE PROCEDURE gas.SampleParams_Fetch 
	@BrandID SmallInt
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT B.BrandID, b.BrandName
    FROM Relational.Brand B
    INNER JOIN Relational.BrandCompetitor BC ON b.BrandID = bc.CompetitorID
    WHERE BC.BrandID = @BrandID
    
END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[SampleParams_Fetch] TO [DB5\reportinguser]
    AS [dbo];

