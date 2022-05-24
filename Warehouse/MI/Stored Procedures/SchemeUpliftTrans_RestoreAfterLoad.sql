-- =============================================
-- Author:		JEA
-- Create date: 22/08/2013
-- Description:	Clears down SchemeUpliftTrans staging table
-- and restores columnstore index
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_RestoreAfterLoad] 
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE MI.SchemeUpliftTrans_Stage

	ALTER INDEX IX_Relational_SchemeUpliftTrans_Cover ON Relational.SchemeUpliftTrans REBUILD
	ALTER INDEX IX_Relational_SchemeUpliftTrans_MonthlyReportFacilitate ON Relational.SchemeUpliftTrans REBUILD
	ALTER INDEX IX_Relational_SchemeUpliftTrans_MemberSalesFacilitate ON Relational.SchemeUpliftTrans REBUILD

END