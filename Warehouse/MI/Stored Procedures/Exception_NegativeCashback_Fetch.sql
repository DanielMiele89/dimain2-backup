-- =============================================
-- Author:		JEA
-- Create date: 18/03/2014
-- Description:	List details for customers who have passed 
-- any of the exception audit test
-- =============================================
CREATE PROCEDURE [MI].[Exception_NegativeCashback_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	SELECT c.SourceUID AS CIN, (f.ClubCashAvailable + F.ClubCashPending) AS NegativeCashback --negative cashback
	FROM SLC_Report.dbo.Fan f
	INNER JOIN Relational.Customer c ON f.ID = c.FanID
	WHERE (f.ClubCashAvailable + F.ClubCashPending) < 0
	AND c.SourceUID NOT LIKE 'T%'

END
