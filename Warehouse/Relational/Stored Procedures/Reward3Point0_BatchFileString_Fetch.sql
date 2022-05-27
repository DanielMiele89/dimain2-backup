/******************************************************************************
Author: Jason Shipp
Created: 15/01/2020
Purpose: 
	-  Fetches batch file string for uploading Reward 3.0 data to S3
------------------------------------------------------------------------------
Modification History

Jason Shipp 13/04/2020
	- Added calls for uploading files to new environment (048) (commented out for now)

******************************************************************************/
CREATE PROCEDURE Relational.Reward3Point0_BatchFileString_Fetch
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @BatchFile TABLE(FileRow VARCHAR(500));
	DECLARE @S3Bucket VARCHAR(50) = 'reward-insight-portal';
	DECLARE @S3Bucket2 VARCHAR(50) = 'dataops-athena-wg-eu-west-2-rwrd048-rwrd-uk';
	DECLARE @Suffix VARCHAR(100) = ' --acl bucket-owner-full-control --profile trusted-analytics-insight-etl-role';
	DECLARE @Suffix2 VARCHAR(100) = ' --acl bucket-owner-full-control --profile trusted-rwd-engineer-etl-role-048';

	INSERT INTO @BatchFile(FileRow)
	VALUES 
		-- 005 environment
		('aws s3 cp ' + 'Reward2Point0_EarningsToDate.txt' + ' s3://' + @S3Bucket + '/businessintelligence/Reward3Point0/Reward2Point0_EarningsToDate/' + @Suffix)
		, ('aws s3 cp ' + 'Reward3Point0_EarningsToDate.txt' + ' s3://' + @S3Bucket + '/businessintelligence/Reward3Point0/Reward3Point0_EarningsToDate/' + @Suffix)
		, ('aws s3 cp ' + 'Reward3Point0_AccountEarnings.txt' + ' s3://' + @S3Bucket + '/businessintelligence/Reward3Point0/Reward3Point0_AccountEarnings/' + @Suffix)
		-- 048 environment
		, ('aws s3 cp ' + 'Reward2Point0_EarningsToDate.txt' + ' s3://' + @S3Bucket2 + '/tableau/rbs/reward3point0/reward2point0-earnings-to-date/' + @Suffix2)
		, ('aws s3 cp ' + 'Reward3Point0_EarningsToDate.txt' + ' s3://' + @S3Bucket2 + '/tableau/rbs/reward3point0/reward3point0-earnings-to-date/' + @Suffix2)
		, ('aws s3 cp ' + 'Reward3Point0_AccountEarnings.txt' + ' s3://' + @S3Bucket2 + '/tableau/rbs/reward3point0/reward3point0-account-earnings/' + @Suffix2);
	
	SELECT FileRow
	FROM @BatchFile;

END