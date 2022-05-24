
-- ***********************************************************
-- Author: Suraj Chahal
-- Create date: 20/08/2015
-- Description: Updates data for Halfords Weekly Report
-- ***********************************************************
CREATE PROCEDURE [Staging].[SSRS_R0097a_Quidco_HalfordsAutoCentreWeeklyReport]

AS
BEGIN
	SET NOCOUNT ON;

SELECT	a.Years,
	a.Week_No,
	a.Start_Date,
	a.End_Date,
	b.NoCardholders,
	a.no_trans as Transactions,
	a.no_spenders as Spenders,
	a.trans_amount as Sales,
	a.commission_exclVat as Investment,
	a.last_tran as Last_Tran_Date
FROM Warehouse.Staging.SSRS_R0097_HalfordsAutoCentreWeeklyReport a
INNER JOIN Warehouse.InsightArchive.HalfordsAutoCentre_Volumes_By_Week b 
	ON b.ActivationDate = a.Start_Date
ORDER BY a.Years, a.Week_No, a.Start_Date

END