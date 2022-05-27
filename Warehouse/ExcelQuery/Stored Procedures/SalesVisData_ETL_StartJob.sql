-- =============================================
-- Author:		JEA
-- Create date: 01/02/2017
-- Description:	launches job to load SalesVisData to REWARDBI
-- =============================================
create PROCEDURE [ExcelQuery].[SalesVisData_ETL_StartJob] 
WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    EXEC msdb.dbo.sp_start_job 'SalesVisDataETL'

END
