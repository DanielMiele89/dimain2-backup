-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE AWSFile.PostCode_NewLocations_SecondStage_Fetch
	
AS
BEGIN

	SET NOCOUNT ON;

    SELECT MerchantID
		, MerchantDBAName
		, MerchantSICClassCode
		, MerchantDBAState
		, MerchantDBACity
		, MerchantZip
		, MerchantDBACountry
		, First_Tran
		, Last_Tran
		, Amount
		, No_Trans
		, RANK( ) OVER (PARTITION BY MerchantID, MerchantDBAName ORDER BY  Last_Tran DESC ) AS Site_No
	FROM AWSFile.PostCode_NewLocations_FirstStage

END