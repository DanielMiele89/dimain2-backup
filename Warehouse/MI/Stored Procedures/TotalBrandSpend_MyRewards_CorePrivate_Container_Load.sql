-- =============================================
-- Author:		JEA
-- Create date: 19/10/2016
-- Description:	Container for load processes
-- for the total brand spend myRewards reports
-- for core and private bank customers
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_MyRewards_CorePrivate_Container_Load] 
	
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @GenerationDate DATE
	SET @GenerationDate = GETDATE()

	TRUNCATE TABLE MI.TotalBrandSpend_MyRewards_CorePrivate
	TRUNCATE TABLE MI.GrandTotalCustomers_MyRewards_CorePrivate
	TRUNCATE TABLE MI.SectorTotalCustomers_MyRewards_CorePrivate
	TRUNCATE TABLE MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate
	TRUNCATE TABLE MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate

	DELETE FROM MI.TotalBrandSpend_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomers_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.SectorTotalCustomers_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.TotalBrandSpendFixedBase_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate
	DELETE FROM MI.GrandTotalCustomersFixedBase_MyRewards_CorePrivate_Archive WHERE GenerationDate = @GenerationDate

	EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_Load 0
	EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_Load 1

END