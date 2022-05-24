-- =============================================
-- Author:		JEA
-- Create date: 05/03/2014
-- Description:	Updates the combination working table 
-- following import from text file
-- =============================================
CREATE PROCEDURE [gas].[SideBySide_ComboList_Update] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE Staging.ConsumerCombinationReview
	SET Narrative = f.narrative
	, IsHighVariance = f.IsHighVariance
	FROM Staging.ConsumerCombinationReview r
	INNER JOIN Staging.ForeignMIDCombos f ON r.ReviewID = f.ReviewID
	WHERE f.IsHighVariance = 1

	TRUNCATE TABLE Staging.ForeignMIDCombos

END