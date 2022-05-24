-- =============================================
-- Author:		JEA
-- Create date: 23/06/2015
-- Description:	Clears tables in preparation for re-run
-- =============================================
CREATE PROCEDURE [MI].[MRR_SingleRetailerTables_Clear] 
	(
		@PartnerID INT
		, @DateID INT
	)
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.Staging_Customer_Temp 
	TRUNCATE TABLE MI.Staging_Customer_TempCUMLandNonCore
	TRUNCATE TABLE MI.Staging_Control_Temp
	TRUNCATE TABLE MI.OutletAttribute
	TRUNCATE TABLE Warehouse.MI.WorkingofferDates
	TRUNCATE TABLE Warehouse.MI.WorkingCumlDates

	DELETE FROM MI.ControlSalesWorking WHERE PartnerID = @PartnerID AND DateID = @DateID
	DELETE FROM MI.MemberssalesWorking WHERE PartnerID = @PartnerID AND DateID = @DateID
	TRUNCATE TABLE MI.INSchemeSalesWorking
	--the three tables below are to be checked for problems with uplift after lack of adjustment factors has been checked
	DELETE FROM RR 
	FROM MI.Uplift_RetailerReport RR 
	INNER JOIN MI.RetailerReportMetric m ON RR.ResultsRowID = M.ID
	WHERE m.PartnerID = @PartnerID AND m.DateID = @DateID

	DELETE FROM MI.Uplift_Results_Table WHERE PartnerID = @PartnerID AND DateID = @DateID

	DELETE FROM mi.RetailerReportMetric WHERE DateID = @DateID AND PartnerID = @PartnerID

	EXEC MI.MRR_NonCoreCustomerStagingTables_Clear

	EXEC MI.MRR_NonCoreCustomerStagingTables_Clear

END