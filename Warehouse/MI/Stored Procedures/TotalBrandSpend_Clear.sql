-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;
	
	TRUNCATE TABLE MI.TotalBrandSpend
	TRUNCATE TABLE MI.GrandTotalCustomers
	TRUNCATE TABLE MI.SectorTotalCustomers
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase

	TRUNCATE TABLE MI.TotalBrandSpend_CBP
	TRUNCATE TABLE MI.GrandTotalCustomers_CBP
	TRUNCATE TABLE MI.SectorTotalCustomers_CBP
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase_CBP
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase_CBP

	TRUNCATE TABLE MI.TotalBrandSpend_MyRewards_CorePrivate
	TRUNCATE TABLE MI.GrandTotalCustomers_MyRewards_CorePrivate
	TRUNCATE TABLE MI.SectorTotalCustomers_MyRewards_CorePrivate
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate

END
