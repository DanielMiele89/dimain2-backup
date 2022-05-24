
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[BatchFile_UpdateBrands_Fetch]

AS
BEGIN


	SET NOCOUNT ON;

	DECLARE @FileLine TABLE(Line VARCHAR(500))
	DECLARE @bucket VARCHAR(50) = 'reward-analytics-coredata'
	DECLARE @region VARCHAR(50) = 'eu-west-1'
	DECLARE @suffix VARCHAR(100) = ' --acl bucket-owner-full-control --profile trusted-analytics-insight-etl-role'
	DECLARE @TransactionTable VARCHAR(500)

	INSERT INTO @FileLine(Line)
    VALUES('aws s3 cp brand\brand.txt s3://' + @bucket + '/brand/' + @suffix)
		, ('aws s3 cp consumercombination\consumercombination.txt s3://' + @bucket + '/consumercombination/' + @suffix)
		, ('aws s3 cp consumercombination_dd\consumercombination_dd.txt s3://' + @bucket + '/ConsumerCombination_DD/' + @suffix)
		, ('aws s3 cp consumercombinationalternate\consumercombinationalternate.txt s3://' + @bucket + '/consumercombinationalternate/' + @suffix)
		--, ('aws s3 cp TotalBrandSpend\TotalBrandSpend.txt s3://aws-athena-query-results-805090266366-eu-west-1/TableauOutput/TotalBrandSpend/' + @suffix)


	SELECT Line
	FROM @FileLine

END

