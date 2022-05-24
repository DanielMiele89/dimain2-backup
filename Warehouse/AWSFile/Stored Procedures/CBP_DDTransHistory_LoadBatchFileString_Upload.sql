/******************************************************************************
Author: Jason Shipp
Created: 01/10/2018
Purpose: 
	- Load batch file string for uploading new direct debit data to S3 and creating new partitions on Athena table
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_LoadBatchFileString_Upload (@UploadFolder VARCHAR(100))
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @BatchFile TABLE(FileRow VARCHAR(500));
	DECLARE @S3Bucket VARCHAR(50) = 'reward-analytics-coredata';
	DECLARE @Region VARCHAR(50) = 'eu-west-1';
	DECLARE @Suffix VARCHAR(100) = ' --acl bucket-owner-full-control --profile trusted-analytics-insight-etl-role';

	INSERT INTO @BatchFile(FileRow)
	VALUES
		('aws s3 cp ' + @UploadFolder + ' s3://' + @S3Bucket + '/DirectDebitTransactionHistory/ --recursive' + @Suffix)
		, ('aws athena start-query-execution --query-string "MSCK REPAIR TABLE directdebittransactionhistory;" --query-execution-context Database=bigpaymentdata --region ' + @region +' --result-configuration "OutputLocation=s3://reward-analytics-queryoutput/etl-output/" --profile trusted-analytics-insight-etl-role');

	SELECT FileRow
	FROM @BatchFile;

END
