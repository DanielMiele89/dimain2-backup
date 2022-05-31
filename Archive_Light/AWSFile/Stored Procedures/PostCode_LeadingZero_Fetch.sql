-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [AWSFile].[PostCode_LeadingZero_Fetch] 
	(
		@FileID INT
	)
AS
BEGIN

	SET NOCOUNT ON;

    SELECT CAST(ct.MerchantID AS varchar(15)) AS MerchantID
		, CAST(RTRIM(LTRIM(ct.MerchantDBAName)) AS VARCHAR(25)) AS MerchantDBAName
		, CAST(ct.MerchantSICClassCode AS varchar(4)) AS MerchantSICClassCode
		, CAST(ct.MerchantDBAState AS varchar(3)) AS MerchantDBAState
		, CAST(ct.MerchantDBACity AS varchar(13)) AS MerchantDBACity
		, CAST(REPLACE(RTRIM(LTRIM(ct.MerchantZip)),' ','') AS varchar(50)) AS MerchantZip
		, CAST(ct.MerchantDBACountry AS varchar(3)) as MerchantDBACountry
		, CAST(MIN(TranDate) AS date) First_Tran
		, CAST(MAX(TranDate) AS date) Last_Tran
		, SUM(ct.amount) Amount
		, COUNT(1) No_Trans
	FROM Archive_Light..CBP_Credit_TransactionHistory ct
	LEFT OUTER JOIN AWSFile.PostCode_NewLocations_FirstStage n ON ct.MerchantID = n.MerchantID
	WHERE LTRIM(ct.MerchantID)<>'' AND REPLACE(RTRIM(LTRIM(ct.MerchantZip)),' ','')='0000' 
	AND n.MerchantID IS NULL
	AND FileID > @FileID
	AND TranDate IS NOT NULL	--	RF 20211011
	GROUP BY ct.MerchantID
		, RTRIM(LTRIM(ct.MerchantDBAName))
		, ct.MerchantSICClassCode
		, ct.MerchantDBAState
		, ct.MerchantDBACity
		, REPLACE(RTRIM(LTRIM(ct.MerchantZip)),' ','')
		, ct.MerchantDBACountry

END
