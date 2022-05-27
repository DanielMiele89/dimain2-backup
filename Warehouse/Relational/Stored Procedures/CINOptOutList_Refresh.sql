-- =============================================
-- Author:		JEA
-- Create date: 02/07/2013
-- Description:	Refreshes the list of customers who are currently offline
-- so that customer bases and attributes can exclude these customers
-- =============================================
CREATE PROCEDURE [Relational].[CINOptOutList_Refresh]
	WITH EXECUTE AS OWNER	
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE Relational.CINOptOutList

	CREATE TABLE #OptOutFan(CIN VARCHAR(50) not null)

	CREATE TABLE #ActiveFan(CIN VARCHAR(50) NOT NULL)

	INSERT INTO #OptOutFan(CIN)
	SELECT DISTINCT c.SourceUID
	FROM MI.CustomerActivationHistory cah
	INNER JOIN (SELECT FanID, MAX(StatusDate) AS StatusDate
				FROM MI.CustomerActivationHistory
				WHERE ActivationStatusID IN (1,2)
				GROUP BY FanID) m on cah.FanID = m.FanID and cah.StatusDate = m.StatusDate
	INNER JOIN Relational.Customer c on cah.FanID = c.FanID
	WHERE cah.ActivationStatusID = 2

	INSERT INTO #ActiveFan(CIN)
	SELECT DISTINCT c.SourceUID
	FROM MI.CustomerActivationHistory cah
	INNER JOIN (SELECT FanID, MAX(StatusDate) AS StatusDate
				FROM MI.CustomerActivationHistory
				WHERE ActivationStatusID IN (1,2)
				GROUP BY FanID) m on cah.FanID = m.FanID and cah.StatusDate = m.StatusDate
	INNER JOIN Relational.Customer c on cah.FanID = c.FanID
	INNER JOIN (SELECT DISTINCT FanID FROM MI.CustomerActivationHistory WHERE ActivationStatusID = 2) O ON CAH.FanID = O.FanID --Customers who have ever opted out
	WHERE cah.ActivationStatusID = 1

	ALTER TABLE #OptOutFan ADD PRIMARY KEY(CIN)
	ALTER TABLE #ActiveFan ADD PRIMARY KEY(CIN)

	INSERT INTO Relational.CINOptOutList(CINID)
	SELECT c.CINID
	FROM Relational.CINList c
	INNER JOIN #OptOutFan o ON c.CIN = o.CIN
	EXCEPT
	SELECT CINID
	FROM Relational.CINOptOutList
	ORDER BY c.CINID

	DELETE FROM Relational.CINOptOutList
	FROM Relational.CINOptOutList c
	INNER JOIN Relational.CINList l on c.CINID = l.CINID
	INNER JOIN #ActiveFan a ON l.CIN = a.CIN

END