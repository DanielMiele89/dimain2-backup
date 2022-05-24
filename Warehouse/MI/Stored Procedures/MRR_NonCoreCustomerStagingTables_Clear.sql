-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.MRR_NonCoreCustomerStagingTables_Clear 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE MI.MRR_Staging_NonCoreCustomers_Stage1
	TRUNCATE TABLE MI.MRR_Staging_NonCoreCustomers_Stage2
	TRUNCATE TABLE MI.MRR_Staging_NonCoreCustomers_Stage3
	TRUNCATE TABLE MI.MRR_Staging_NonCoreCustomers_Stage4
	TRUNCATE TABLE MI.MRR_Staging_NonCoreCustomers_Stage5    

END