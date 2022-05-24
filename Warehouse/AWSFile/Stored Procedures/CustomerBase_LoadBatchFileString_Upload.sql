/******************************************************************************
Author: Jason Shipp
Created: 13/08/2018
Purpose:
	- Load string for loading into batch file via SSIS, instructing load of new Fixed Base data to S3
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CustomerBase_LoadBatchFileString_Upload (
	@LastMonthYYYYMM VARCHAR(50)
	, @FolderName VARCHAR(50)
)
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		'aws s3 cp ' -- Full directory not needed as working directory (where batch file is situated) is same as where text file to upload is situated
		+ 'FixedBase'+ @LastMonthYYYYMM 
		+ '.txt s3://reward-analytics-queryinput/FixedBase/'
		+ @FolderName
		+ '/ --acl bucket-owner-full-control --profile trusted-analytics-insight-etl-role' AS BatchLine;
		
END