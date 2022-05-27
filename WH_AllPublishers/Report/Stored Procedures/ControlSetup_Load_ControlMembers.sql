/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Load nFI PartnerIDs to run segmentations for
	- Load validation of retailer offers to be segmented
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 10/04/2019
	-- Added partner settings for MFDD partners
		
******************************************************************************/
CREATE PROCEDURE [Report].[ControlSetup_Load_ControlMembers]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	/*******************************************************************************************************************************************
		1.	Declare stored procedure names and Load MFDD PartnerIDs
	*******************************************************************************************************************************************/

		DECLARE @ControlSegmentationSP_POS varchar(100) = '[Segmentation].[ControlSetup_Segmentation_POS]';
		DECLARE @ControlSegmentationSP_DD varchar(100) = '[Segmentation].[ControlSetup_Segmentation_DD]';
		

	/*******************************************************************************************************************************************
		2.	Store MFDD Retailers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#MFDDPartners') IS NOT NULL DROP TABLE #MFDDPartners;
		SELECT	DISTINCT
				dd.PartnerID
		INTO #MFDDPartners
		FROM [Warehouse].[Segmentation].[PartnerSettings_DD] dd
		UNION
		SELECT	DISTINCT
				pa.PartnerID
		FROM [Warehouse].[Segmentation].[PartnerSettings_DD] dd
		INNER JOIN [Warehouse].[APW].[PartnerAlternate] pa
			ON dd.PartnerID = pa.AlternatePartnerID
		UNION 
		SELECT	DISTINCT
				pa.PartnerID
		FROM [Warehouse].[Segmentation].[PartnerSettings_DD] dd
		INNER JOIN [nFI].[APW].[PartnerAlternate] pa
			ON dd.PartnerID = pa.AlternatePartnerID;
			

	/*******************************************************************************************************************************************
		3.	Create table of segmentation calls
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ToSegment') IS NOT NULL DROP TABLE #ToSegment;
		SELECT	cg.Execution
			,	cg.TableName
			,	cg.SchemaName
			,	cg.RetailerID
			,	cg.StartDate
			,	cg.EndDate
			,	ROW_NUMBER() OVER(ORDER BY cg.RetailerID ASC) AS RowNo
		INTO #ToSegment
		FROM (	SELECT	DISTINCT -- The below code creates paramater values for this stored procedure
						'EXEC '	+	CASE
										WHEN cg.RetailerID IN (SELECT PartnerID FROM #MFDDPartners) THEN @ControlSegmentationSP_DD
										ELSE @ControlSegmentationSP_POS
									END
								+	' '
								+	COALESCE(CONVERT(VARCHAR(5), cg.RetailerID), 'NULL')
								+	','''
								+	CONVERT(VARCHAR(10), cg.StartDate, 20)
								+	''',''Sandbox.'
								+	SYSTEM_USER
								+	'.Control_'
								+	COALESCE(CONVERT(VARCHAR(5), cg.RetailerID), 'Universal')
								+	'_'
								+	CONVERT(VARCHAR(10), cg.StartDate, 112) AS Execution
					,	cg.RetailerID
					,	cg.StartDate
					,	cg.EndDate
					,	SYSTEM_USER AS SchemaName
					,	'Control_' + COALESCE(CONVERT(VARCHAR(5), cg.RetailerID), 'Universal') + '_' + CONVERT(VARCHAR(10), cg.StartDate, 112) as TableName
				FROM [Report].[ControlSetup_ControlGroupIDs] cg
				WHERE IsSegmented = 0
				AND IsInPromgrammeControlGroup = 0) cg;


	/*******************************************************************************************************************************************
		4.	Execute segmentation calls to segment customers & load them to Sandbox tables & ControlGroupMembers
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#ToSegmentLoop') IS NOT NULL DROP TABLE #ToSegmentLoop;
		SELECT	ts.Execution
			,	ts.TableName
			,	ts.SchemaName
			,	'Sandbox.' + ts.SchemaName + '.' + ts.TableName AS FullTableName
			,	ts.RetailerID
			,	ts.StartDate
			,	ts.EndDate
			,	ts.RowNo
		INTO #ToSegmentLoop
		FROM #ToSegment ts
		WHERE 1 = 2
		
		IF OBJECT_ID('tempdb..#ToInsertLoop') IS NOT NULL DROP TABLE #ToInsertLoop;
		SELECT	tsl.FullTableName
			,	tsl.RetailerID
			,	cg.ControlGroupID
			,	cg.SegmentID
		INTO #ToInsertLoop
		FROM #ToSegmentLoop tsl
		INNER JOIN [Report].[ControlSetup_ControlGroupIDs] cg
			ON tsl.RetailerID = cg.RetailerID
			AND tsl.StartDate = cg.StartDate
			AND tsl.EndDate = cg.EndDate
		WHERE 1 = 2

		DECLARE @RowNo INT = 1
			,	@RowNoMax INT = (SELECT	MAX(RowNo) FROM #ToSegment)
			,	@Query NVARCHAR(MAX)
			,	@TableName VARCHAR(500)
			,	@Execution VARCHAR(500);

		DECLARE	@ControlGroupID INT
			,	@ControlGroupIDMax INT
			,	@SegmentID INT

		DECLARE	@InsertToCGM_Execution NVARCHAR(MAX)

		WHILE @RowNo <= @RowNoMax
			BEGIN
				
				TRUNCATE TABLE #ToSegmentLoop
				INSERT INTO #ToSegmentLoop
				SELECT	ts.Execution
					,	ts.TableName
					,	ts.SchemaName
					,	'Sandbox.' + SchemaName + '.' + TableName AS FullTableName
					,	ts.RetailerID
					,	ts.StartDate
					,	ts.EndDate
					,	ts.RowNo
				FROM #ToSegment ts
				WHERE RowNo = @RowNo

				SELECT	@TableName = FullTableName
					,	@Execution = Execution
				FROM #ToSegmentLoop

				SET @Query = '
				IF OBJECT_ID (''' + @TableName + ''') IS NOT NULL DROP TABLE ' + @TableName + '
				' + @Execution + ''''

				EXEC (@Query)

				TRUNCATE TABLE #ToInsertLoop
				INSERT INTO #ToInsertLoop
				SELECT	tsl.FullTableName
					,	tsl.RetailerID
					,	cg.ControlGroupID
					,	cg.SegmentID
				FROM #ToSegmentLoop tsl
				INNER JOIN [Report].[ControlSetup_ControlGroupIDs] cg
					ON tsl.RetailerID = cg.RetailerID
					AND tsl.StartDate = cg.StartDate
					AND tsl.EndDate = cg.EndDate
				WHERE cg.IsSegmented = 0
				ORDER BY cg.ControlGroupID

				SELECT	@ControlGroupID = MIN(ControlGroupID)
					,	@ControlGroupIDMax = MAX(ControlGroupID)
				FROM #ToInsertLoop

				WHILE @ControlGroupID <= @ControlGroupIDMax
					BEGIN

						SELECT	@SegmentID = SegmentID
						FROM #ToInsertLoop
						WHERE ControlGroupID = @ControlGroupID

						IF EXISTS (SELECT 1 FROM [Report].[OfferReport_ControlGroupMembers] cgm WHERE cgm.ControlGroupID = @ControlGroupID)
							BEGIN
								DELETE cgm
								FROM [Report].[OfferReport_ControlGroupMembers] cgm
								WHERE cgm.ControlGroupID = @ControlGroupID
							END

						SET @InsertToCGM_Execution = '
						INSERT INTO [Report].[OfferReport_ControlGroupMembers]
						SELECT	TOP (950000)
								' + CONVERT(VARCHAR(10), @ControlGroupID) + ' AS ControlGroupID
							,	FanID
						FROM ##TableName##
						WHERE SegmentID IN ##SegmentID##
						ORDER BY ABS(CHECKSUM(NEWID()))'

			
						SET @InsertToCGM_Execution = REPLACE(@InsertToCGM_Execution, '##TableName##', @TableName)

						IF @SegmentID = 7 SET @InsertToCGM_Execution = REPLACE(@InsertToCGM_Execution, '##SegmentID##', '(7)')
						IF @SegmentID = 8 SET @InsertToCGM_Execution = REPLACE(@InsertToCGM_Execution, '##SegmentID##', '(8)')
						IF @SegmentID = 9 SET @InsertToCGM_Execution = REPLACE(@InsertToCGM_Execution, '##SegmentID##', '(9)')
						IF @SegmentID = 0 SET @InsertToCGM_Execution = REPLACE(@InsertToCGM_Execution, 'WHERE SegmentID IN ##SegmentID##', '')

						EXEC (@InsertToCGM_Execution)

						;WITH
						OfferReport_ControlGroupMembers_Counts AS (SELECT	DISTINCT
																			cg.RetailerID
																		,	cg.SegmentID
																		,	cg.ControlGroupID
																		,	cg.StartDate
																		,	cg.EndDate
																		,	@@ROWCOUNT AS Customers
																		,	GETDATE() AS AddedDate
																		,	GETDATE() AS ModifiedDate
																	FROM #ToSegmentLoop tsl
																	INNER JOIN [Report].[ControlSetup_ControlGroupIDs] cg
																		ON tsl.RetailerID = cg.RetailerID
																		AND tsl.StartDate = cg.StartDate
																		AND tsl.EndDate = cg.EndDate
																	WHERE cg.ControlGroupID = @ControlGroupID)


						MERGE [Report].[OfferReport_ControlGroupMembers_Counts] target			-- Destination table
						USING OfferReport_ControlGroupMembers_Counts source					-- Source table
						ON target.ControlGroupID = source.ControlGroupID						-- Match criteria

						WHEN MATCHED THEN
							UPDATE SET	target.RetailerID		= source.RetailerID	-- If matched, update to new value
									,	target.SegmentID		= source.SegmentID
									,	target.ControlGroupID	= source.ControlGroupID
									,	target.StartDate		= source.StartDate
									,	target.EndDate			= source.EndDate
									,	target.Customers		= source.Customers
									,	target.ModifiedDate		= source.ModifiedDate

						WHEN NOT MATCHED THEN											-- If not matched, add new rows
							INSERT (RetailerID
								,	SegmentID
								,	ControlGroupID
								,	StartDate
								,	EndDate
								,	Customers
								,	AddedDate)
							VALUES (source.RetailerID
								,	source.SegmentID
								,	source.ControlGroupID
								,	source.StartDate
								,	source.EndDate
								,	source.Customers
								,	source.AddedDate);

						UPDATE cg
						SET cg.IsSegmented = 1
						FROM [Report].[ControlSetup_ControlGroupIDs] cg
						WHERE cg.ControlGroupID = @ControlGroupID
						AND EXISTS (SELECT 1
									FROM [Report].[OfferReport_ControlGroupMembers] cgm
									WHERE cg.ControlGroupID = cgm.ControlGroupID)

						SELECT	@ControlGroupID = MIN(ControlGroupID)
						FROM #ToInsertLoop
						WHERE @ControlGroupID < ControlGroupID

					END

				SET @RowNo = @RowNo + 1
			END

END