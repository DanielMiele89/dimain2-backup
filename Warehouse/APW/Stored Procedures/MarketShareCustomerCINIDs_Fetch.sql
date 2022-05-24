-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Retrieves customers on MyRewards
-- who have been active since the beginning of the
-- last complete month.
-- =============================================
CREATE PROCEDURE [APW].[MarketShareCustomerCINIDs_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @MonthDate DATE
	SET @MonthDate = DATEADD(MONTH, -1, DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1)) -- First day of the last completed month
	
    SELECT CIN.CINID, CAST(1 AS BIT) AS IsSchemeMember
	FROM Relational.CINList CIN
	INNER JOIN Relational.Customer c ON CIN.CIN = c.SourceUID
	LEFT OUTER JOIN MI.CINDuplicate d ON c.FanID = d.FanID
	WHERE c.ActivatedDate <= @MonthDate
	AND c.CurrentlyActive = 1
	AND d.FanID IS NULL

END