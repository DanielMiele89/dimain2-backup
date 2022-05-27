-- =============================================
-- Author:		JEA
-- Create date: 07/10/2015
-- Description:	Returns activations and migrations 
-- to MyRewards Front Book
-- =============================================
CREATE PROCEDURE [MI].[FrontBookActivationMigration_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @FrontBookStart DATE = '2015-10-12'

	CREATE TABLE #Clubs(ClubID INT PRIMARY KEY
						, BankName VARCHAR(50) NOT NULL)

	CREATE TABLE #ChangeType(ID TINYINT PRIMARY KEY IDENTITY
		, ChangeType VARCHAR(100) NOT NULL
		, HeaderColour VARCHAR(50)
		, RowColour VARCHAR(50))

	INSERT INTO #ChangeType(ChangeType)
	SELECT DISTINCT ChangeType FROM MI.FrontBookStatusType

	UPDATE #ChangeType SET HeaderColour = '#9d9d9d', RowColour = '#F2f2f2'
	WHERE ID % 2 = 0

	UPDATE #ChangeType SET HeaderColour = '#bcbcbc', RowColour = 'white'
	WHERE ID % 2 != 0

	INSERT INTO #Clubs(ClubID, BankName)
	VALUES (132, 'NatWest'), (138, 'RBS')

	--This table to be used to make sure that values for all types are displayed even when there are no results
	CREATE TABLE #ChangeTypeClubDate(ID INT PRIMARY KEY IDENTITY
		, StartDate DATE NOT NULL
		, ClubID INT NOT NULL
		, BankName VARCHAR(50) NOT NULL
		, ChangeType VARCHAR(100) NOT NULL
		, HeaderColour VARCHAR(50) NOT NULL
		, RowColour VARCHAR(50) NOT NULL)

	INSERT INTO #ChangeTypeClubDate(StartDate, ClubID, BankName, ChangeType, HeaderColour, RowColour)
	SELECT d.StartDate, c.ClubID, c.BankName, s.ChangeType, s.HeaderColour, s.RowColour
	FROM
	( --all relevant dates
		SELECT AddedDate AS StartDate
		FROM Staging.SchemeUpliftTrans_Day
		WHERE AddedDate	BETWEEN @FrontBookStart AND DATEADD(DAY, -1, GETDATE())
	)d
	CROSS JOIN #Clubs c --natwest and rbs
	CROSS JOIN #ChangeType s

	SELECT c.StartDate, c.BankName, c.ChangeType, ISNULL(s.CustomerCount, 0) AS CustomerCount, c.HeaderColour, c.RowColour
	FROM
	#ChangeTypeClubDate c
	LEFT OUTER JOIN
	(
		SELECT s.ClubID, s.StartDate, f.ChangeType, COUNT(1) AS CustomerCount
		FROM
		(
			SELECT c.ClubID, s.StartDate, s.SchemeMembershipTypeID, s.PrevSchemeID
			FROM (
					SELECT s.FanID, s.StartDate, s.SchemeMembershipTypeID, LAG(s.SchemeMembershipTypeID, 1, 0) OVER (PARTITION BY s.FanID ORDER BY StartDate) AS PrevSchemeID
					FROM Relational.Customer_SchemeMembership s
				) s
			INNER JOIN Relational.Customer c ON s.FanID = c.FanID
			WHERE s.SchemeMembershipTypeID IN (6,7) --front book scheme membership types
			AND s.StartDate >= @FrontBookStart --start of Phase 2
		) s
		INNER JOIN MI.FrontBookStatusType f ON s.SchemeMembershipTypeID = f.SchemeMembershipTypeID AND s.PrevSchemeID = f.PrevSchemeID
		GROUP BY s.ClubID, s.StartDate, f.ChangeType

	) s ON c.StartDate = s.StartDate AND C.ClubID = S.ClubID AND C.ChangeType = s.ChangeType

	DROP TABLE #Clubs
	DROP TABLE #ChangeTypeClubDate

END
