-- =============================================
-- Author:		JEA
-- Create date: 25/07/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [RBSMIPortal].[LoyaltyTables_Clear]

AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE RBSMIPortal.Customer
	TRUNCATE TABLE RBSMIPortal.CalendarWeekMonth
	TRUNCATE TABLE RBSMIPortal.BrandListInfo
	TRUNCATE TABLE RBSMIPortal.SchemeCashback

END