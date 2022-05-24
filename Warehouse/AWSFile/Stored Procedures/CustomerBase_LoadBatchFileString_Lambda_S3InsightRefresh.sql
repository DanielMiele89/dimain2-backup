/******************************************************************************
Author: Jason Shipp
Created: 15/08/2018
Purpose:
	- Load string for loading into batch file via SSIS, instructing the refresh of Insight files on S3 via a Lambda Python call
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CustomerBase_LoadBatchFileString_Lambda_S3InsightRefresh
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		'aws lambda invoke --invocation-type RequestResponse --function-name arn:aws:lambda:eu-west-1:805090266366:function:FixedBase_S3InsightRefresh --region eu-west-1 --payload "{"key1": "value1"}" --log-type Tail output.txt' AS BatchLine;
		
END