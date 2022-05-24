-- =============================================
-- Author:		JEA
-- Create date: 14/10/2015
-- =============================================
CREATE PROCEDURE [MI].[MRR_InSchemeAndMember_WorkingTables_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	ALTER INDEX IX_MRR_Customer_Working_Cover ON MI.MRR_Customer_Working DISABLE

    TRUNCATE TABLE MI.MRR_InSchemeSales_Working
	TRUNCATE TABLE MI.MRR_MemberSales_Working
	TRUNCATE TABLE MI.MRR_Customer_Working

END
