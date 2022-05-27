-- =============================================
-- Author:		JEA
-- Create date: 23/09/2013
-- Description:	Refreshes the CustomerActivationPeriod table
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Refresh] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.CustomerActivationPeriod

	INSERT INTO MI.CustomerActivationPeriod(ID, FanID, ActivationStart)
	SELECT ID, FanID, StatusDate
	FROM MI.CustomerActivationHistory
	WHERE ActivationStatusID = 1

	UPDATE MI.CustomerActivationPeriod
	SET ActivationEnd = O.StatusDate
	FROM MI.CustomerActivationPeriod p
	INNER JOIN (SELECT ID, FanID, StatusDate
				FROM MI.CustomerActivationHistory
				WHERE ActivationStatusID = 2) O
					ON P.FanID = O.FanID 
					AND P.ActivationStart <= o.StatusDate
					AND (P.ActivationEnd IS NULL OR p.ActivationEnd < o.StatusDate)

	UPDATE MI.CustomerActivationPeriod
	SET ActivationEnd = d.StatusDate
	FROM MI.CustomerActivationPeriod p
	INNER JOIN (SELECT ID, FanID, StatusDate
				FROM MI.CustomerActivationHistory
				WHERE ActivationStatusID = 3) d
					ON P.FanID = d.FanID 
					AND P.ActivationStart <= d.StatusDate
					AND (P.ActivationEnd IS NULL OR p.ActivationEnd < d.StatusDate)


END
