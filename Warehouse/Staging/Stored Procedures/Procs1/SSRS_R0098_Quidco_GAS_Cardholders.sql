
-- ***********************************************************
-- Author: Suraj Chahal
-- Create date: 21/08/2015
-- Description: Finds Cardholders for Report
-- ***********************************************************
CREATE PROCEDURE [Staging].[SSRS_R0098_Quidco_GAS_Cardholders]

AS
BEGIN
	SET NOCOUNT ON;

SELECT	*
FROM Warehouse.Staging.SSRS_R0098_Quidco_Cards

END