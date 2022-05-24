-- =============================================
-- Author:		JEA
-- Create date: 30/09/2013
-- Description:	Checks CustomerActivationPeriod with customer active status
-- =============================================
CREATE PROCEDURE [MI].[CustomerActivationPeriod_Customer_Update]

AS
BEGIN

	SET NOCOUNT ON;

	UPDATE cas 
		SET OptedOutDate = i.OptedOutDate
	FROM MI.CustomerActiveStatus cas
	INNER JOIN (
		SELECT FanID, MAX(ActivationDate) AS OptedOutDate
		FROM MI.CustomersInactive
		WHERE ActivationStatusID = 2
		GROUP BY FanID
	) i ON cas.FanID = i.FanID
	WHERE cas.ActivatedDate <= I.OptedOutDate


	UPDATE cas 
		SET DeactivatedDate = i.DeactivatedDate
	FROM MI.CustomerActiveStatus cas
	INNER JOIN (
		SELECT FanID, MAX(ActivationDate) AS DeactivatedDate
		FROM MI.CustomersInactive
		WHERE ActivationStatusID = 3
		GROUP BY FanID
	) i ON cas.FanID = i.FanID
	WHERE cas.ActivatedDate <= I.DeactivatedDate


	UPDATE cas 
		SET DeactivatedDate = NULL, OptedOutDate = NULL
	FROM MI.CustomerActiveStatus cas
	INNER JOIN SLC_Report.dbo.Fan c ON cas.FanID = c.ID
	WHERE c.[Status] = 1 AND c.AgreedTCs = 1 AND c.AgreedTCsDate IS NOT NULL
	AND (cas.DeactivatedDate IS NOT NULL OR cas.OptedOutDate IS NOT NULL)
	and c.id != 7879318
	and c.id != 14393387

	UPDATE MI.CustomerActiveStatus set ActivationMethodID = 1

	UPDATE cas SET ActivationMethodID = 2
	FROM MI.CustomerActiveStatus cas
	INNER JOIN Relational.Customer cu ON cas.FanID = cu.FanID
	WHERE cu.ActivatedOffline = 1



	UPDATE cap 
		SET ActivationEnd = i.NonActiveDate
	FROM Staging.CustomerActivationPeriod cap
	INNER JOIN (
		SELECT c.ID, c.FanID, c.ActivationStart, c.NextActive, MIN(i.ActivationDate) AS NonActiveDate
		FROM (
			SELECT ID, FanID, ActivationStart, LEAD(ActivationStart, 1) OVER(PARTITION BY FanID ORDER BY ActivationStart) AS NextActive
			FROM Staging.CustomerActivationPeriod
		) c
		INNER JOIN MI.CustomersInactive i ON c.FanID = i.FanID
		WHERE (i.ActivationDate BETWEEN c.ActivationStart AND c.NextActive
			OR c.NextActive IS NULL)
			AND c.ActivationStart <= i.ActivationDate
		GROUP BY c.ID, c.FanID, c.ActivationStart, c.NextActive
	) i ON cap.ID = i.ID
	-- n / 01:30:00


    UPDATE cap --Staging.CustomerActivationPeriod CJM 20180622
		SET ActivationEnd = NULL
	FROM Staging.CustomerActivationPeriod cap
	INNER JOIN (
		SELECT MAX(p.ID) AS ID, p.FanID
		FROM Staging.CustomerActivationPeriod p
		INNER JOIN Relational.Customer c ON P.FanID = C.FanID
		WHERE c.CurrentlyActive = 1
		GROUP BY p.FanID
	) c ON cap.ID = c.ID and cap.FanID = c.FanID
	WHERE cap.ActivationEnd IS NOT NULL

END
