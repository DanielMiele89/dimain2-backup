-- =============================================
-- Author:		JEA
-- Create date: 19/06/2017
-- Description:	launches job to load ROC forecasting data to REWARDBI
-- =============================================
CREATE PROCEDURE [MI].[PepsMVP_ETL_StartJob] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    EXEC msdb.dbo.sp_start_job 'PepsMVPRefresh'

END