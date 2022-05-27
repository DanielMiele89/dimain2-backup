/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose:
	- Create table of Warehouse segmentation calls
	- Execute segmentation calls: load retailer segmented control group members into new tables in user's Sandbox schema	

------------------------------------------------------------------------------
Modification History

Jason Shipp 11/09/2019
	- Added logic to dynamic SQL generation:
	- Calls Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro for CLO retailer segmentation
	- Calls Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD for CLO retailer segmentation

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Segment_Control_Members]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Declare stored procedure names and Load MFDD PartnerIDs
	******************************************************************************/

	DECLARE @CLOSegmentStoredProcedure varchar(100) = 'Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_V3_Control_Retro';
	DECLARE @MFDDSegmentStoredProcedure varchar(100) = 'Warehouse.Segmentation.ROC_Shopper_Segmentation_Individual_Partner_Control_MFDD';

	IF OBJECT_ID('tempdb..#MFDDPartners') IS NOT NULL DROP TABLE #MFDDPartners;

	SELECT DISTINCT
	dd.PartnerID
	INTO #MFDDPartners
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	UNION
	SELECT
	pa.PartnerID
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	INNER JOIN Warehouse.APW.partnerAlternate pa
	ON dd.PartnerID = pa.AlternatePartnerID
	UNION 
	SELECT
	pa.PartnerID
	FROM Warehouse.Segmentation.PartnerSettings_DD dd
	INNER JOIN nFI.APW.partnerAlternate pa
	ON dd.PartnerID = pa.AlternatePartnerID;

	/******************************************************************************
	- Create table of segmentation calls
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
					'EXEC '	+	CASE
									WHEN pts.PartnerID IN (SELECT PartnerID FROM #MFDDPartners) THEN @MFDDSegmentStoredProcedure
									ELSE @CLOSegmentStoredProcedure
								END
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
			FROM [Warehouse].[Staging].[ControlSetup_PartnersToSeg_Warehouse] pts) pts
	LEFT JOIN Sandbox.sys.tables t
		ON pts.TableName = t.name

	--SELECT *
	--FROM #ALS_Execution_Requests

	/******************************************************************************
	Execute segmentation calls
	******************************************************************************/

	Declare
		@ALS_RN int = 1
		, @ALS_RNMax int = (Select Max(RowNo) From #ALS_Execution_Requests)
		, @Qry nvarchar(max);

	While @ALS_RN <= @ALS_RNMax

	Begin
		
		If object_id (concat(
			'Sandbox.'
			, (select SchemaName from #ALS_Execution_Requests where RowNo = @ALS_RN)
			, '.'
			, (select TableName from #ALS_Execution_Requests where RowNo = @ALS_RN)
		)) is not null

		Begin
			Set @ALS_RN = @ALS_RN+1; -- Skip execution if table already exists (Eg. as part of nFI setup)
		End

		Else	
			
			Begin
				Set @Qry = (select Execution From #ALS_Execution_Requests Where RowNo = @ALS_RN);
				Exec sp_executeSQL @Qry;
				Set @ALS_RN = @ALS_RN+1;
			End
	End

END