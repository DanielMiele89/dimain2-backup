
-- =============================================
-- Author:		JEA
-- Create date: 10/09/2014
-- Description:	Refreshes the RewardBI.CustomerActiveStatus0 table
-- =============================================
CREATE PROCEDURE [RewardBI].[CustomerActiveStatus_Refresh] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE RewardBI.CustomerActiveStatus

	INSERT INTO RewardBI.CustomerActiveStatus(FanID
		, ActivatedDate
		, DeactivatedDate
		, OptedOutDate
		)

	SELECT a.FanID
		, a.ActivatedDate
		--when a customer has been activated as the most recent action, deactivated and opt out dates should be NULL
		, CASE WHEN A.LastActiveDate > d.DeactivatedDate THEN NULL ELSE d.DeactivatedDate END AS DeactivatedDate
		, CASE WHEN A.LastActiveDate > o.OptedOutDate THEN NULL ELSE o.OptedOutDate END AS OptedOutDate
	FROM
	(
		SELECT FanID, MIN(StatusDate) AS ActivatedDate, MAX(StatusDate) AS LastActiveDate
		FROM RewardBI.CustomerActivationLog
		WHERE ActivationStatusID = 1 --activated customers
		GROUP BY FanID
	) a
	LEFT OUTER JOIN
	( 
		SELECT FanID, MAX(StatusDate) AS DeactivatedDate
		FROM RewardBI.CustomerActivationLog
		WHERE ActivationStatusID = 3 --deactivated customers
		GROUP BY FanID 
	) d ON a.FanID = d.FanID
	LEFT OUTER JOIN
	( 
		SELECT FanID, MAX(StatusDate) AS OptedOutDate
		FROM RewardBI.CustomerActivationLog
		WHERE ActivationStatusID = 2 --opt out customers
		GROUP BY FanID 
	) o ON a.FanID = o.FanID

	UPDATE RewardBI.CustomerActiveStatus SET DeactivatedDate = NULL, OptedOutDate = NULL
	FROM RewardBI.CustomerActiveStatus ca
	INNER JOIN Relational.Customer c on ca.FanId = c.FanID
	WHERE (ca.DeactivatedDate IS NOT NULL OR ca.OptedOutDate IS NOT NULL) AND c.CurrentlyActive = 1

	UPDATE RewardBI.CustomerActiveStatus SET DeactivatedDate = c.DeactivatedDate
	FROM RewardBI.CustomerActiveStatus ca
	INNER JOIN Relational.Customer c on ca.FanId = c.FanID
	WHERE (ca.DeactivatedDate IS NOT NULL AND ca.OptedOutDate IS NOT NULL) AND c.CurrentlyActive = 0

END

