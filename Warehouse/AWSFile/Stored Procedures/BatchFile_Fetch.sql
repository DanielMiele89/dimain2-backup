﻿
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[BatchFile_Fetch] 
	(
		@UploadFolder VARCHAR(50)
		, @UpdateConsumerTrans BIT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @FileLine TABLE(Line VARCHAR(500))
	DECLARE @bucket VARCHAR(50) = 'reward-analytics-coredata'
	DECLARE @region VARCHAR(50) = 'eu-west-1'
	DECLARE @suffix VARCHAR(100) = ' --acl bucket-owner-full-control --profile trusted-analytics-insight-etl-role'

	INSERT INTO @FileLine(Line)
    VALUES('aws s3 cp brand\brand.txt s3://' + @bucket + '/brand/' + @suffix)
	, ('aws s3 cp consumercombination\consumercombination.txt s3://' + @bucket + '/consumercombination/' + @suffix)
	, ('aws s3 cp consumercombinationalternate\consumercombinationalternate.txt s3://' + @bucket + '/consumercombinationalternate/' + @suffix)
	, ('aws s3 cp location\location.txt s3://' + @bucket + '/location/' + @suffix)
	, ('aws s3 cp alternatelocation\alternatelocation.txt s3://' + @bucket + '/alternatelocation/' + @suffix)
	, ('aws s3 cp customer\customer.txt s3://' + @bucket + '/customer/' + @suffix)

	IF @UpdateConsumerTrans = 1
	BEGIN
	INSERT INTO @FileLine(Line)
	VALUES ('aws s3 cp ' + @UploadFolder + '\consumertransaction s3://' + @bucket + '/consumertransaction/ --recursive' + @suffix)
	, ('aws athena start-query-execution --query-string "MSCK REPAIR TABLE consumertransaction;" --query-execution-context Database=bigpaymentdata --region ' + @region +' --result-configuration "OutputLocation=s3://reward-analytics-queryoutput/etl-output/" --profile trusted-analytics-insight-etl-role') --lambda commented out until resolved with Joe
	END

	SELECT Line
	FROM @FileLine

END

