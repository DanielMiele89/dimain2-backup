/******************************************************************************
-- Author:		JEA
-- Create date: 21/06/2018
-- Description:	Executes required tasks after pipe load to Warehouse.APW.SchemeTrans_Pipe is complete
------------------------------------------------------------------------------
Modification History

Jason Shipp 26/06/2018
	- Added entry-write to JobLog Table
	- Added job to trigger SSIS package to feed Flash Offer Report
	- Added jobs to trigger email subscriptions for Flash Offer Report and Flash Transaction Report

Jason Shipp 24/12/2018
	- Added logic to only run flash reports on weekdays

******************************************************************************/
CREATE PROCEDURE [APW].[SchemeTrans_Pipe_PostLoadOperations] 
	
AS
BEGIN

	SET NOCOUNT ON;

	EXEC APW.SchemeTrans_Pipe_PostLoadProcessing; -- Update IsRetailerReport flag in Warehouse.APW.SchemeTrans_Pipe

	IF (SELECT DATENAME(dw, GETDATE())) IN ('Wednesday')
	BEGIN	
		--EXEC Staging.FlashTransactionReport_Load_Trigger; -- Load data for Flash Transaction Report	
		--EXEC msdb.dbo.sp_start_job 'AF274787-D877-4FB8-A356-59E9721B46AE'; -- FlashTransactionResults_BespokeAggregation email trigger for Morrisons
		--EXEC msdb.dbo.sp_start_job 'A01744D1-ADC1-4C26-B720-505F817E67F0'; -- FlashTransactionResults_BespokeAggregation email trigger for Waitrose
		--EXEC msdb.dbo.sp_start_job 'B6B67CCA-283A-47F0-A81F-6DC8659C42B2'; -- FlashTransactionResults_BespokeAggregation email trigger for Now TV
	
		EXEC msdb.dbo.sp_start_job 'FlashOfferReport'; -- Run SSIS package to load Flash Offer Report data, and trigger email subscriptions
	END

END