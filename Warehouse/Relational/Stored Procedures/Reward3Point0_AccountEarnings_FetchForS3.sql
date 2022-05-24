/******************************************************************************
Author: Jason Shipp
Created: 15/11/2019
Purpose: 
	- For Reward 3.0 reporting
	- Fetches earnings data per account, for uploading to S3, from the Warehouse.Relational.Reward3Point0_AccountEarnings table

------------------------------------------------------------------------------
Modification History

Jason Shipp 30/03/2020
	- Swapped IssuerBankAccountID for BankAccountID

******************************************************************************/
CREATE PROCEDURE Relational.Reward3Point0_AccountEarnings_FetchForS3
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT
		d.CalculationDate
		, d.StartDate
		, d.EndDate
		, CAST(d.IsCurrentMonth AS int) AS IsCurrentMonth
		, d.BankAccountID AS IssuerBankAccountID -- Name as IssuerBankAccountID to maintain consistency with Tableau Report
		, d.PublisherID
		, d.PublisherName
		, d.MostRecentAccountTypeCode AS AccountTypeCode
		, d.MostRecentAccountType AS AccountType
		, d.AccountStartDate
		, d.AccountEndDate
		, CAST(d.IsJointAccount AS int) AS IsJointAccount
		, d.NomineeFanID
		, d.Gender
		, d.AgeBucketName
		, d.PostcodeDistrict
		, d.Region
		, d.DDMinEarningDate 
		, d.MobileLoginMinEarningDate
		, d.DDMaxEarningDate
		, d.MobileLoginMaxEarningDate
		, d.DDEarnings
		, d.MobileLoginEarnings
		, CASE
			WHEN d.DDEarnings = 0 AND d.MobileLoginEarnings = 0 THEN 'No earnings'
			WHEN d.DDEarnings > 0 AND d.MobileLoginEarnings = 0 THEN 'DD earnings only'
			WHEN d.DDEarnings = 0 AND d.MobileLoginEarnings > 0 THEN 'Mobile login earnings only'
			WHEN d.DDEarnings > 0 AND d.MobileLoginEarnings > 0 THEN 'DD and mobile login earnings'
			ELSE NULL 
		END AS EarnStatus
	FROM Warehouse.Relational.Reward3Point0_AccountEarnings d;

END