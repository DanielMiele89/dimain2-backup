-- =============================================
-- Author:		JEA
-- Create date: 11/11/2014
-- Description:	Updates the customer Activation period from staging.
-- This procedure was introduced following the need to record when entries
-- to the MI.CustomerActivationPeriod table
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Staging_Update]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	CREATE TABLE #CustomerActivationPeriod_Archive (FanID INT, ActivationStart DATE, ActivationEnd DATE, AddedDate DATE, UpdatedDate DATE)

	DELETE c
	OUTPUT deleted.FanID, deleted.ActivationStart, deleted.ActivationEnd, deleted.AddedDate, deleted.UpdatedDate INTO #CustomerActivationPeriod_Archive
	FROM MI.CustomerActivationPeriod c
	WHERE NOT EXISTS (SELECT 1 FROM Staging.CustomerActivationPeriod s WHERE C.FanID = s.FanID AND c.ActivationStart = S.ActivationStart)

	INSERT INTO MI.CustomerActivationPeriod_Archive (FanID, ActivationStart, ActivationEnd, AddedDate, UpdatedDate)
	SELECT FanID, ActivationStart, ActivationEnd, AddedDate, UpdatedDate FROM #CustomerActivationPeriod_Archive 


	INSERT INTO MI.CustomerActivationPeriod (FanID, ActivationStart, ActivationEnd, AddedDate)
	SELECT s.FanID, s.ActivationStart, s.ActivationEnd, GETDATE()
	FROM Staging.CustomerActivationPeriod s
	WHERE NOT EXISTS (SELECT 1 FROM MI.CustomerActivationPeriod c WHERE C.FanID = s.FanID AND c.ActivationStart = S.ActivationStart)

	UPDATE c 
		SET ActivationEnd = s.ActivationEnd, UpdatedDate = GETDATE()
	FROM MI.CustomerActivationPeriod c
	INNER JOIN Staging.CustomerActivationPeriod s ON c.FanID = s.FanID AND c.ActivationStart = s.ActivationStart
	WHERE (c.ActivationEnd IS NULL AND s.ActivationEnd IS NOT NULL)
		OR (c.ActivationEnd IS NOT NULL AND s.ActivationEnd IS NULL)
		OR (c.ActivationEnd != s.ActivationEnd)

END