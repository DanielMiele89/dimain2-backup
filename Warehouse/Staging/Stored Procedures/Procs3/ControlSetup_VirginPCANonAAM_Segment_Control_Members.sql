
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
CREATE PROCEDURE [Staging].[ControlSetup_VirginPCANonAAM_Segment_Control_Members]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	DECLARE stored procedure names AND Load MFDD PartnerIDs
	******************************************************************************/

		DECLARE @CLOSegmentStoredProcedure VARCHAR(100) = 'Warehouse.Segmentation.ControlGroupSegmentation_VirginPCA';


	/******************************************************************************
	- CREATE TABLE of segmentation calls
	- Create new paramater values to be called with each execution of the ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro stored procedure
	******************************************************************************/

	If object_id('tempdb..#ALS_Execution_Requests') is not null drop table #ALS_Execution_Requests;
	Select	Execution
		,	TableName
		,	SchemaName
		,	ROW_NUMBER() OVER(ORDER BY pts.PartnerID ASC) AS RowNo
		,	CASE
				WHEN t.name IS NULL THEN 0
				ELSE 1
			END AS TableExists
	Into #ALS_Execution_Requests
	FROM (	SELECT	DISTINCT -- The below code creates paramater values for this stored procedure
					'EXEC '	+	@CLOSegmentStoredProcedure
							+	' '
							+	COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'NULL')
							+	','''
							+	CONVERT(VARCHAR(10), pts.StartDate, 20)
							+	''',''Sandbox.'
							+	SYSTEM_USER
							+	'.Control_'
							+	COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'Universal')
							+	'_'
							+	CONVERT(VARCHAR(10), pts.StartDate, 112)
							+	'''' AS Execution
				,	pts.PartnerID
				,	SYSTEM_USER as SchemaName
				,	'Control_' + COALESCE(CONVERT(VARCHAR(5), pts.PartnerID), 'Universal') + '_' + CONVERT(VARCHAR(10), pts.StartDate, 112) as TableName
			FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_VirginPCA] pts) pts
	LEFT JOIN Sandbox.sys.tables t
		ON pts.TableName = t.name
	WHERE t.name IS NULL

	--SELECT *
	--FROM #ALS_Execution_Requests

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