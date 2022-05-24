-- =============================================
-- Author:		JEA
-- Create date: 31/05/2015
-- Description:	Disables indexes on the customer tables prior to insert
-- =============================================
CREATE PROCEDURE [MI].[MRR_CustomerIndexes_Disable] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--MI.Staging_Control_Temp
	ALTER INDEX IND_Date ON MI.Staging_Control_Temp DISABLE
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Control_Temp DISABLE
	ALTER INDEX IND_Partner ON MI.Staging_Control_Temp DISABLE
	
	IF EXISTS(SELECT * FROM sys.objects WHERE name = 'UN_FANCuml2' AND type_desc = 'UNIQUE_CONSTRAINT')
	BEGIN
		ALTER TABLE MI.Staging_Control_Temp DROP CONSTRAINT [UN_FANCuml2]
	END

	--MI.Staging_Customer_Temp
	ALTER INDEX IND_Date ON MI.Staging_Customer_Temp DISABLE
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Customer_Temp DISABLE
	ALTER INDEX IND_Partner ON MI.Staging_Customer_Temp DISABLE
	IF EXISTS(SELECT * FROM sys.objects WHERE name = 'UN_FANCuml3' AND type_desc = 'UNIQUE_CONSTRAINT')
	BEGIN
		ALTER TABLE MI.Staging_Customer_Temp DROP CONSTRAINT [UN_FANCuml3]
	END

	--MI.Staging_Customer_TempCUMLandNonCore
	ALTER INDEX IND_Date ON MI.Staging_Customer_TempCUMLandNonCore DISABLE
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Customer_TempCUMLandNonCore DISABLE
	ALTER INDEX IND_Partner ON MI.Staging_Customer_TempCUMLandNonCore DISABLE
	IF EXISTS(SELECT * FROM sys.objects WHERE name = 'UN_FANCuml' AND type_desc = 'UNIQUE_CONSTRAINT')
	BEGIN
		ALTER TABLE MI.Staging_Customer_TempCUMLandNonCore DROP CONSTRAINT [UN_FANCuml]
	END
	ALTER INDEX IX_NCL_Staging_Customer_TempCUMLandNonCore_MemberSales ON MI.Staging_Customer_TempCUMLandNonCore DISABLE

END