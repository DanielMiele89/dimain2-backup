

-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 15/09/2015
-- Description: DD Report 
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0102_DirectDebit_TransReport]
									
AS
BEGIN
	SET NOCOUNT ON;


SELECT	*
FROM Warehouse.Staging.R_0102_DD_DataTable
WHERE CAST(StartOfMonth AS DATE) BETWEEN '2015-08-01' AND DATEADD(DAY,-DAY(GETDATE()),CAST(GETDATE() AS DATE)) 


END