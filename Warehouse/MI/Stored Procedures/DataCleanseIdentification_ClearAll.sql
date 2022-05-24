
CREATE PROCEDURE [MI].[DataCleanseIdentification_ClearAll]
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.DataCleanseIdentification
	TRUNCATE TABLE MI.DataCleanseIdentification_Brands
	

END