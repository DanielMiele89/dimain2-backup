/******************************************************************************
Author: Jason Shipp
Created: 17/03/2020
Purpose: 
	- For Reward 3.0 reporting
	- Fetches total earnings to date for Reward 3.0 direct debits and mobile logins, for uploading to S3
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Relational.Reward3Point0_EarningsToDate_FetchForS3
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		CAST(GETDATE() AS date) AS CalculationDate
		, f.ClubID AS PublisherID
		, CASE f.ClubID WHEN 132 THEN 'NatWest' WHEN 138 THEN 'RBS' ELSE NULL END AS PublisherName
		, SUM(t.ClubCash*tt.Multiplier) AS Earnings_Reward3Point0 
	FROM SLC_Report.dbo.Trans t
	INNER JOIN SLC_Report.dbo.TransactionType tt
		ON t.TypeID = tt.ID
	INNER JOIN SLC_Report.dbo.Fan f
		ON t.FanID = f.ID
	WHERE
		t.TypeID IN (29, 31)
		AND EXISTS (SELECT NULL FROM SLC_Report.dbo.IssuerBankAccount iba WHERE t.IssuerBankAccountID = iba.ID)
	GROUP BY
		f.ClubID;
	
END