-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE Prototype.Affinity_LastFileProcessed_Set
	(
		@LastFileProcessed INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

    UPDATE Prototype.LastFileProcessedAffinity
	SET FileID = @LastFileProcessed

END