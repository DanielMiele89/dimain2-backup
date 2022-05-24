-- =============================================
-- Author:		JEA
-- Create date: 04/07/2013
-- Description:	Refreshes the Staging.CustomerActiveStatus table
-- =============================================
CREATE PROCEDURE [MI].[CustomerActiveStatus_Refresh] 
	
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.CustomerActiveStatus

	INSERT INTO MI.CustomerActiveStatus(FanID
		, ActivatedDate
		, DeactivatedDate
		, OptedOutDate
		, IsRBS)

	SELECT a.FanID
		, a.ActivatedDate
		--when a customer has been activated as the most recent action, deactivated and opt out dates should be NULL
		, CASE WHEN A.LastActiveDate > d.DeactivatedDate THEN NULL ELSE d.DeactivatedDate END AS DeactivatedDate
		, CASE WHEN A.LastActiveDate > o.OptedOutDate THEN NULL ELSE o.OptedOutDate END AS OptedOutDate
		, a.IsRBS
	FROM
	(
		SELECT FanID, MIN(StatusDate) AS ActivatedDate, MAX(StatusDate) AS LastActiveDate, IsRBS
		FROM MI.CustomerActivationHistory
		WHERE ActivationStatusID = 1 --activated customers
		GROUP BY FanID, IsRBS
	) a
	LEFT OUTER JOIN
	( 
		SELECT FanID, MAX(StatusDate) AS DeactivatedDate
		FROM MI.CustomerActivationHistory
		WHERE ActivationStatusID = 3 --deactivated customers
		GROUP BY FanID 
	) d ON a.FanID = d.FanID
	LEFT OUTER JOIN
	( 
		SELECT FanID, MAX(StatusDate) AS OptedOutDate
		FROM MI.CustomerActivationHistory
		WHERE ActivationStatusID = 2 --opt out customers
		GROUP BY FanID 
	) o ON a.FanID = o.FanID

	UPDATE MI.CustomerActiveStatus SET DeactivatedDate = NULL, OptedOutDate = NULL
	FROM MI.CustomerActiveStatus ca
	INNER JOIN Relational.Customer c on ca.FanId = c.FanID
	WHERE (ca.DeactivatedDate IS NOT NULL OR ca.OptedOutDate IS NOT NULL) AND c.CurrentlyActive = 1

	UPDATE MI.CustomerActiveStatus SET DeactivatedDate = c.DeactivatedDate
	FROM MI.CustomerActiveStatus ca
	INNER JOIN Relational.Customer c on ca.FanId = c.FanID
	WHERE (ca.DeactivatedDate IS NOT NULL AND ca.OptedOutDate IS NOT NULL) AND c.CurrentlyActive = 0

END
