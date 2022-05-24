
/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose:
	- CREATE TABLE of nFI segmentation calls
	- Execute segmentation calls: load retailer segmented control group members INTO new tables in user's Sandbox schema	

------------------------------------------------------------------------------
Modification History

Jason Shipp 11/09/2019
	- Added logic to dynamic SQL generation:
	- Calls Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro for CLO retailer segmentation
	- Calls Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD for CLO retailer segmentation
	
******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_VisaBarclaycardNonAAM_Segment_Control_Members_20211201]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	DECLARE stored procedure names AND Load MFDD PartnerIDs
	******************************************************************************/

		DECLARE @CLOSegmentStoredProcedure VARCHAR(100) = 'Warehouse.Segmentation.ControlGroupSegmentation_VisaBarclaycard';


	/******************************************************************************
	- CREATE TABLE of segmentation calls
	- Create new paramater values to be called with each execution of the ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro stored procedure
	******************************************************************************/

		IF OBJECT_ID('tempdb..#ALS_Execution_Requests') IS NOT NULL DROP TABLE #ALS_Execution_Requests;
		SELECT	Execution = 'EXEC ' + StoredProcedure + ' ' + PartnerID_Varchar + ', ''' + StartDate_Varchar1 + ''',''Sandbox.' + SchemaName + '.Control_' + PartnerID_Varchar + '_' + StartDate_Varchar2 + ''''
			,	'Sandbox.' + SchemaName + '.Control_' + PartnerID_Varchar + '_' + StartDate_Varchar2 AS TableName
			,	SchemaName
			,	ROW_NUMBER() OVER (ORDER BY a.PartnerID ASC) AS RowNo
		INTO #ALS_Execution_Requests
		FROM (	SELECT	DISTINCT -- The below code creates paramater values for this stored procedure
						@CLOSegmentStoredProcedure AS StoredProcedure
					,	CONVERT(VARCHAR(5), pts.PartnerID) AS PartnerID_Varchar
					,	CONVERT(VARCHAR(10), pts.StartDate, 20) AS StartDate_Varchar1
					,	CONVERT(VARCHAR(10), pts.StartDate, 112) AS StartDate_Varchar2
					,	pts.PartnerID
					,	SYSTEM_USER AS SchemaName
				FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VisaBarclaycard] pts) a;

	/******************************************************************************
	Execute segmentation calls
	******************************************************************************/

		DECLARE	@ALS_RN INT = 1
			,	@ALS_RNMax INT = (SELECT MAX(RowNo) FROM #ALS_Execution_Requests)
			,	@Qry NVARCHAR(MAX);

		WHILE @ALS_RN <= @ALS_RNMax
	
		BEGIN
		
			IF OBJECT_ID ((SELECT TableName FROM #ALS_Execution_Requests WHERE RowNo = @ALS_RN)) IS NOT NULL
				BEGIN
					SET @ALS_RN = @ALS_RN+1; -- Skip execution if table already exists (Eg. AS part of Warehouse setup)
				END
			ELSE
				BEGIN
					SELECT @Qry = Execution
					FROM #ALS_Execution_Requests
					WHERE RowNo = @ALS_RN;

					EXEC sp_executeSQL @Qry;
					SET @ALS_RN = @ALS_RN + 1;
				END

		END	

END