-- =============================================
-- Author:		JEA
-- Create date: 01/06/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_ControlSpendDates_Set] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

	DELETE FROM APW.ControlBase WHERE PseudoActivatedMonthID IS NULL

    UPDATE c
	SET PrePeriodStartDate = d.PrePeriodStartDate, PrePeriodEndDate = d.PrePeriodEndDate
	FROM APW.ControlBase c
	INNER JOIN APW.ControlDates d ON c.PseudoActivatedMonthID = d.ID

	--ALTER INDEX IXNCL_APW_ControlBase_PrePeriodDateRange ON APW.ControlBase REBUILD 
	ALTER INDEX IXNCL_APW_ControlBase_PrePeriodDateRange ON APW.ControlBase REBUILD WITH (DATA_COMPRESSION = PAGE)

END