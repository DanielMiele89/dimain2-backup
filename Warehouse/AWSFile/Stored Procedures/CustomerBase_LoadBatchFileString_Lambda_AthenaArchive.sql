/******************************************************************************
Author: Jason Shipp
Created: 15/08/2018
Purpose:
	- Load string for loading into batch file via SSIS, instructing the Archive of the Fixed Base table on Athena via a Lambda Python call
		
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CustomerBase_LoadBatchFileString_Lambda_AthenaArchive
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT 
		'aws lambda invoke --invocation-type RequestResponse --function-name arn:aws:lambda:eu-west-1:805090266366:function:FixedBase_AthenaArchive --region eu-west-1 --payload "{"key1": "value1"}" --log-type Tail output.txt' AS BatchLine;
		
END