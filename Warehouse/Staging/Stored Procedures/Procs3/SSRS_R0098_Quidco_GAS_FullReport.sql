
-- ***********************************************************
-- Author: Suraj Chahal
-- Create date: 21/08/2015
-- Description: Find Data for Report
-- ***********************************************************
CREATE PROCEDURE [Staging].[SSRS_R0098_Quidco_GAS_FullReport]

AS
BEGIN
	SET NOCOUNT ON;

SELECT	*
FROM Warehouse.Staging.SSRS_R0098_Quidco_GASReport
ORDER BY (CASE
		WHEN Reporting_Period = 'Last Month' THEN 1
		WHEN Reporting_Period = 'Current Month' THEN 2
		ELSE 3
	END)

END