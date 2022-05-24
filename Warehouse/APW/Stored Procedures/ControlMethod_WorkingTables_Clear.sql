-- =============================================
-- Author:		JEA
-- Create date: 31/05/2016
-- Description:	Clears working tables for control methodology
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_WorkingTables_Clear] 
WITH EXECUTE AS OWNER	
AS
BEGIN

	SET NOCOUNT ON;

	ALTER INDEX IXNCL_APW_ControlBase_PrePeriodDateRange ON APW.ControlBase DISABLE

	TRUNCATE TABLE APW.CustomersActive
	TRUNCATE TABLE APW.CustomersActiveSpend
	TRUNCATE TABLE APW.ControlBase
	TRUNCATE TABLE APW.ControlBase_PseudoActivationAssign
	TRUNCATE TABLE APW.ControlBaseSpend
	TRUNCATE TABLE APW.ControlAdjusted
	TRUNCATE TABLE APW.ControlAdjustmentFactor
	TRUNCATE TABLE APW.ControlRetailerSpend
	TRUNCATE TABLE APW.ControlStats
	TRUNCATE TABLE APW.CustomersActiveRetailerSpend
	TRUNCATE TABLE APW.CustomersActiveStats

	UPDATE APW.ControlExposedPercentageMakeup
	SET ExposedSize = 0
		, ExposedShare = 0
		, ControlSize = 0
		, ControlShare = 0
		, AdjustedControlSize = 0

END
