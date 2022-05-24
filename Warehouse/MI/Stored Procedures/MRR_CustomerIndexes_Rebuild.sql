-- =============================================
-- Author:		JEA
-- Create date: 31/05/2015
-- Description:	Disables indexes on the customer tables prior to insert
-- =============================================
CREATE PROCEDURE [MI].[MRR_CustomerIndexes_Rebuild] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	--MI.Staging_Control_Temp
	ALTER INDEX IND_Date ON MI.Staging_Control_Temp REBUILD
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Control_Temp REBUILD
	ALTER INDEX IND_Partner ON MI.Staging_Control_Temp REBUILD
	
	ALTER TABLE MI.Staging_Control_Temp ADD  CONSTRAINT [UN_FANCuml2] UNIQUE NONCLUSTERED 
	(
		FanID ASC,
		ProgramID ASC,
		PartnerID ASC,
		ClientServicesRef ASC,
		PeriodTypeID ASC,
		DateID ASC,
		CumulativeTypeID ASC
	)

	--MI.Staging_Customer_Temp
	ALTER INDEX IND_Date ON MI.Staging_Customer_Temp REBUILD
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Customer_Temp REBUILD
	ALTER INDEX IND_Partner ON MI.Staging_Customer_Temp REBUILD

	ALTER TABLE MI.Staging_Customer_Temp ADD  CONSTRAINT [UN_FANCuml3] UNIQUE NONCLUSTERED 
	(
		FanID ASC,
		ProgramID ASC,
		PartnerID ASC,
		ClientServicesRef ASC,
		PeriodTypeID ASC,
		DateID ASC,
		CumulativeTypeID ASC
	)

	--MI.Staging_Customer_TempCUMLandNonCore
	ALTER INDEX IND_Date ON MI.Staging_Customer_TempCUMLandNonCore REBUILD
	ALTER INDEX IND_FanIDCumulativeType ON MI.Staging_Customer_TempCUMLandNonCore REBUILD
	ALTER INDEX IND_Partner ON MI.Staging_Customer_TempCUMLandNonCore REBUILD
	
	ALTER TABLE MI.Staging_Customer_TempCUMLandNonCore ADD  CONSTRAINT UN_FANCuml UNIQUE NONCLUSTERED 
	(
		FanID ASC,
		ProgramID ASC,
		PartnerID ASC,
		ClientServicesRef ASC,
		PeriodTypeID ASC,
		DateID ASC,
		CumulativeTypeID ASC
	)

	ALTER INDEX IX_NCL_Staging_Customer_TempCUMLandNonCore_MemberSales ON MI.Staging_Customer_TempCUMLandNonCore REBUILD

END