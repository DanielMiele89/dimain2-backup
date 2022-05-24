-- =============================================
-- Author: Suraj Chahal
-- Create date: 10/07/2014
-- Description: Finds all customers in the lion.NominatedLionSendComponent table who have either
--		deactivated, unsubscribed or have a postcode under 3 characters
-- =============================================
CREATE PROCEDURE [Staging].[SSRS_R0039_LionSend_EmailExclusions]

AS
BEGIN
	SET NOCOUNT ON;

IF OBJECT_ID ('tempdb..#LionSendIDs') IS NOT NULL DROP TABLE #LionSendIDs
SELECT	DISTINCT
	LionSendID
INTO #LionSendIDs
FROM Warehouse.Lion.NominatedLionSendComponent


SELECT	FanID as [Customer ID],
	Email,
	ClubID,
	ExclusionReason
FROM	(
	SELECT	DISTINCT c.FanID,
		Email,
		c.ClubID,
		'Deactivated' as ExclusionReason
	FROM Warehouse.Lion.NominatedLionSendComponent nl
	INNER JOIN Warehouse.Relational.Customer c
		ON nl.CompositeID = c.CompositeID
	WHERE	LionSendID IN (SELECT DISTINCT LionSendID FROM #LionSendIDs)
		AND c.CurrentlyActive = 0
UNION ALL
	SELECT	DISTINCT c.FanID,
		Email,
		c.ClubID,
		'Not Marketable by Email' as ExclusionReason
	FROM Warehouse.Lion.NominatedLionSendComponent nl
	INNER JOIN Warehouse.Relational.Customer c
		ON nl.CompositeID = c.CompositeID
	WHERE	LionSendID IN (SELECT DISTINCT LionSendID FROM #LionSendIDs)
		AND c.MarketableByEmail = 0
		AND c.CurrentlyActive = 1
		AND LEN(c.PostCode) >=3
UNION ALL
	SELECT	DISTINCT c.FanID,
		Email,
		c.ClubID,
		'Postcode less than 3 characters' as ExclusionReason
	FROM Warehouse.Lion.NominatedLionSendComponent nl
	INNER JOIN Warehouse.Relational.Customer c
		ON nl.CompositeID = c.CompositeID
	WHERE	LionSendID IN (SELECT DISTINCT LionSendID FROM #LionSendIDs)
		AND LEN(c.PostCode) <3
UNION ALL
	SELECT	DISTINCT c.FanID,
		Email,
		c.ClubID,
		'Unsubscribed' as ExclusionReason
	FROM Warehouse.Lion.NominatedLionSendComponent nl
	INNER JOIN Warehouse.Relational.Customer c
		ON nl.CompositeID = c.CompositeID
	WHERE	LionSendID IN (SELECT DISTINCT LionSendID FROM #LionSendIDs)
		AND c.Unsubscribed = 1
		AND MarketableByEmail = 0 
		AND c.CurrentlyActive = 1
		AND LEN(c.PostCode) >=3
	)a
WHERE a.FanID <> 1923715

END