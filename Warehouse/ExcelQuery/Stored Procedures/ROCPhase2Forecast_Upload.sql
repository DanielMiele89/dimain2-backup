
/*=================================================================================================
Uploading the Data from Excel
Part 1: Data Upload
Version 1: 
=================================================================================================*/



CREATE PROCEDURE [ExcelQuery].[ROCPhase2Forecast_Upload]
(
	@brandID as INT
)

WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE ExcelQuery.ROCPhase2Forecast_DownloadBrand

	INSERT INTO ExcelQuery.ROCPhase2Forecast_DownloadBrand
	SELECT @brandID

END
;