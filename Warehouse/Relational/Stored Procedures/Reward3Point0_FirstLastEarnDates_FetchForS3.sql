/******************************************************************************
Author: Jason Shipp
Created: 18/12/2019
Purpose: 
	- For Reward 3.0 reporting
	- Fetches account start, first and last earn dates, as of the max-calculation date per publisher, for uploading to S3, from the Warehouse.Relational.Reward3Point0_FirstLastEarnDates table

------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Relational.Reward3Point0_FirstLastEarnDates_FetchForS3
	
AS
BEGIN
	
	SET NOCOUNT ON;

	WITH MaxPubCalcDates AS (
		SELECT 
		d.PublisherID
		, d.PublisherName
		, MAX(d.CalculationDate) AS MaxCalculationDate
		FROM Relational.Reward3Point0_FirstLastEarnDates d
		GROUP BY
		d.PublisherID
		, d.PublisherName
	)
	SELECT
		d.CalculationDate
		, d.PublisherID
		, d.PublisherName
		, d.IssuerBankAccountID
		, d.MostRecentAccountTypeCode
		, d.MostRecentAccountType
		, d.AccountStartDate
		, d.AccountEndDate
		, d.DDMinEarningDate
		, d.MobileLoginMinEarningDate
		, d.DDMaxEarningDate
		, d.MobileLoginMaxEarningDate
	FROM Warehouse.Relational.Reward3Point0_FirstLastEarnDates d
	INNER JOIN MaxPubCalcDates m
		ON d.PublisherID = m.PublisherID
		AND d.PublisherName = m.PublisherName
		AND d.CalculationDate = m.MaxCalculationDate;
			
END