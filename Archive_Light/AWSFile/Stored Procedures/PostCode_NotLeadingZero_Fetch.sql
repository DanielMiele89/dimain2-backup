-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[PostCode_NotLeadingZero_Fetch] 
	(
		@FileID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CAST(MerchantID AS varchar(15)) AS MerchantID
		, CAST(RTRIM(LTRIM(MerchantDBAName)) AS VARCHAR(25)) AS MerchantDBAName
		, CAST(MerchantSICClassCode AS varchar(4)) AS MerchantSICClassCode
		, CAST(MerchantDBAState AS varchar(3)) AS MerchantDBAState
		, CAST(MerchantDBACity AS varchar(13)) AS MerchantDBACity
		, CAST(REPLACE(RTRIM(LTRIM(MerchantZip)),' ','') AS varchar(50)) AS MerchantZip
		, CAST(MerchantDBACountry AS varchar(3)) as MerchantDBACountry
		, CAST(MIN(TranDate) AS date) First_Tran
		, CAST(MAX(TranDate) AS date) Last_Tran
		, SUM(amount) Amount
		, COUNT(1) No_Trans
	FROM Archive_Light..CBP_Credit_TransactionHistory
	WHERE   LTRIM(MerchantID)<>'' AND REPLACE(RTRIM(LTRIM(MerchantZip)),' ','')<>'0000'
	AND FileID > @FileID
	AND TranDate IS NOT NULL	--	RF 20211011
	GROUP BY MerchantID
		, RTRIM(LTRIM(MerchantDBAName))
		, MerchantSICClassCode
		,MerchantDBAState
		,MerchantDBACity
		,REPLACE(RTRIM(LTRIM(MerchantZip)),' ','')
		,MerchantDBACountry

END
