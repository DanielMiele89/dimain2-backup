-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	launches job to load ROC forecasting data to REWARDBI
-- =============================================
create PROCEDURE [ExcelQuery].[ROCForecastingTool_ETL_StartJob] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    EXEC msdb.dbo.sp_start_job 'ROCForecastingTool Refresh'

END