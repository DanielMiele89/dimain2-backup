/******************************************************************************
Author: Jason Shipp
Created: 15/11/2019
Purpose: 
	- For Reward 3.0 reporting
	- Fetches account counts as of the max-calculation date per publisher, for uploading to S3, from the Warehouse.Relational.Reward3Point0_Accounts table

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Relational.Reward3Point0_Accounts_FetchForS3
	
AS
BEGIN
	
	SET NOCOUNT ON;

	WITH MaxPubCalcDates AS (
		SELECT 
		EndDate
		, PublisherID
		, PublisherName
		, AccountTypeCode
		, AccountType
		, MAX(CalculationDate) AS MaxCalculationDate
		FROM Relational.Reward3Point0_Accounts
		GROUP BY
		EndDate
		, PublisherID
		, PublisherName
		, AccountTypeCode
		, AccountType
	)
	SELECT
		d.ID
		, d.CalculationDate
		, d.EndDate
		, d.PublisherID
		, d.PublisherName
		, d.AccountTypeCode
		, d.AccountType
		, d.Accounts
	FROM Warehouse.Relational.Reward3Point0_Accounts d
	INNER JOIN MaxPubCalcDates m
		ON d.EndDate = m.EndDate
		AND d.PublisherID = m.PublisherID
		AND d.PublisherName = m.PublisherName
		AND d.AccountTypeCode = m.AccountTypeCode
		AND d.AccountType = m.AccountType
		AND d.CalculationDate = m.MaxCalculationDate;
			
END