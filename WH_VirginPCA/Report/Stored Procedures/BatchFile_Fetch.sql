
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [Report].[BatchFile_Fetch] 
	(
		@UploadFolder VARCHAR(50)
		--, @UpdateConsumerTrans BIT
	)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @FileLine TABLE(Line VARCHAR(500))
	DECLARE @bucket VARCHAR(50) = 'dataops-athena-wg-eu-west-2-rwrd048-rwrd-uk'
	DECLARE @region VARCHAR(50) = 'eu-west-2'
	DECLARE @suffix VARCHAR(100) = '--recursive --acl bucket-owner-full-control --profile trusted-rwd-engineer-etl-role-048'
	

	IF 1=1 --@UpdateConsumerTrans = 1
	BEGIN
	INSERT INTO @FileLine(Line)
	VALUES ('aws s3 cp ' + @UploadFolder + '\redemptionitems s3://' + @bucket + '/redemptionitems/ ' + @suffix)
	--, ('aws athena start-query-execution --query-string "MSCK REPAIR TABLE consumertransaction;" --query-execution-context Database=bigpaymentdata --region ' + @region +' --result-configuration "OutputLocation=s3://reward-analytics-queryoutput/etl-output/" --profile trusted-analytics-insight-etl-role') --lambda commented out until resolved with Joe
	END

	SELECT Line
	FROM @FileLine

END

