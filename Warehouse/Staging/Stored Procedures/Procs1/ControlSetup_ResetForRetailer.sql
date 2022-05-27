/******************************************************************************
Author: Jason Shipp
Created: 28/03/2018
Purpose: 
	Resets control groups for a set of nFI or Warehouse IronOfferIDs
Notes:
	THIS STILL NEEDS TO BE TESTED AS OF 28/03/2018
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE Staging.ControlSetup_ResetForRetailer
(
    @IronOfferID VARCHAR(MAX) -- List of ironofferids, seperated by commas or newlines
    , @CycleStartDate DATE
	, @IsWarehouse BIT
)

AS
BEGIN
	
	SET NOCOUNT ON;

	/******************************************************************************
	Set up variables
	******************************************************************************/
	
	DECLARE 
		@CycleEndDate DATE = DATEADD(DAY, -1, (DATEADD(WEEK, 4, @CycleStartDate)))
		, @RowNum INT
		, @MaxRow INT
		, @Qry NVARCHAR(MAX);

	SET @IronOfferID = REPLACE(REPLACE(@IronOfferID, CHAR(13) + CHAR(10), ','), ', ', ',');
	
	/******************************************************************************
	Reset Warehouse offers
	******************************************************************************/

	IF @IsWarehouse = 1

	BEGIN

		-- Load IronOfferCyclesIDs to delete

		If OBJECT_ID('tempdb..#IronOfferCyclesIDs_ToReset_Warhouse') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_ToReset_Warhouse;

		SELECT
			ioc.ironoffercyclesid
			, ioc.controlgroupid
		INTO #IronOfferCyclesIDs_ToReset_Warhouse
		FROM Warehouse.Relational.IronOfferCycles ioc
		INNER JOIN Warehouse.Relational.OfferCycles cyc
			ON ioc.offercyclesid = cyc.OfferCyclesID
		WHERE
			CHARINDEX(',' + CAST(ioc.IronOfferID AS VARCHAR) + ',', ',' + @IronOfferID + ',') > 0 -- Match input IronOfferIDs
			AND CAST(cyc.StartDate AS DATE) BETWEEN @CycleStartDate AND @CycleEndDate; -- Match cycle dates

		-- Delete from IronOfferCycles

		DELETE ioc FROM Warehouse.Relational.IronOfferCycles ioc
		INNER JOIN #IronOfferCyclesIDs_ToReset_Warhouse re
			ON ioc.ironoffercyclesid = re.ironoffercyclesid
	
		-- Delete from IronOffer_References

		DELETE ior FROM Warehouse.Relational.IronOffer_References ior
		INNER JOIN #IronOfferCyclesIDs_ToReset_Warhouse re
			ON ior.ironoffercyclesid = re.ironoffercyclesid

		-- Delete from ControlGroupMember_Counts

		DELETE cc FROM Warehouse.Relational.ControlGroupMember_Counts cc
		INNER JOIN #IronOfferCyclesIDs_ToReset_Warhouse re
			ON cc.ControlGroupID = re.controlgroupid
		WHERE cc.StartDate BETWEEN @CycleStartDate AND @CycleEndDate; -- Match cycle dates

		-- Delete from SecondaryControlGroups

		--DELETE scg FROM Warehouse.Relational.SecondaryControlGroups scg
		--INNER JOIN #IronOfferCyclesIDs_ToReset_Warhouse re
		--	ON scg.ironoffercyclesid = re.ironoffercyclesid

		-- Load quereies to drop user Sandbox control member tables

		IF OBJECT_ID('tempdb..#DropTable_Execution_Requests_Warehouse') IS NOT NULL DROP TABLE #DropTable_Execution_Requests_Warehouse;

		SELECT
			x.Query
			, ROW_NUMBER() OVER(ORDER BY x.Query) AS RowNum
		INTO #DropTable_Execution_Requests_Warehouse
		FROM
			(SELECT DISTINCT
				'IF OBJECT_ID('''
				+'Sandbox.'
				+System_User
				+'.Control'
				+CAST(iof.PartnerID AS VARCHAR(4))
				+CONVERT(VARCHAR(10), @CycleStartDate,112)
				+''') IS NOT NULL DROP TABLE '
				++'Sandbox.'
				+System_User
				+'.Control'
				+CAST(iof.PartnerID AS VARCHAR(4))
				+CONVERT(VARCHAR(10), @CycleStartDate,112)
				AS Query
			FROM Warehouse.Relational.IronOffer iof
			WHERE
				CHARINDEX(',' + CAST(iof.IronOfferID AS VARCHAR) + ',', ',' + @IronOfferID + ',') > 0 -- Match input IronOfferIDs
				AND CAST(iof.StartDate AS DATE) <= @CycleEndDate  -- Match cycle dates
				AND (CAST(iof.EndDate AS DATE) >= @CycleStartDate OR iof.EndDate IS NULL)
			) x;

		-- Execute quereies to drop user Sandbox control member tables

		SET @RowNum = 1;
		SET @MaxRow = (SELECT Max(RowNum) From #DropTable_Execution_Requests_Warehouse);
		
		WHILE @RowNum <= @MaxRow

		BEGIN
	
			SET @Qry = (SELECT Query FROM #DropTable_Execution_Requests_Warehouse WHERE RowNum = @RowNum);

			EXEC sp_executeSQL @Qry;

			Set @RowNum = @RowNum +1;
		END

	END 

	/******************************************************************************
	Reset nFI offers
	******************************************************************************/

	IF @IsWarehouse = 0
	
	BEGIN

		-- Load IronOfferCyclesIDs to delete

		If OBJECT_ID('tempdb..#IronOfferCyclesIDs_ToReset_nFI') IS NOT NULL DROP TABLE #IronOfferCyclesIDs_ToReset_nFI;

		SELECT
			ioc.ironoffercyclesid
			, ioc.controlgroupid
		INTO #IronOfferCyclesIDs_ToReset_nFI
		FROM nFI.Relational.IronOfferCycles ioc
		INNER JOIN nFI.Relational.OfferCycles cyc
			ON ioc.offercyclesid = cyc.OfferCyclesID
		WHERE
			CHARINDEX(',' + CAST(ioc.IronOfferID AS VARCHAR) + ',', ',' + @IronOfferID + ',') > 0 -- Match input IronOfferIDs
			AND CAST(cyc.StartDate AS DATE) BETWEEN @CycleStartDate AND @CycleEndDate; -- Match cycle dates

		-- Delete from IronOfferCycles

		DELETE ioc FROM nFI.Relational.IronOfferCycles ioc
		INNER JOIN #IronOfferCyclesIDs_ToReset_nFI re
			ON ioc.ironoffercyclesid = re.ironoffercyclesid
	
		-- Delete from IronOffer_References

		DELETE ior FROM nFI.Relational.IronOffer_References ior
		INNER JOIN #IronOfferCyclesIDs_ToReset_nFI re
			ON ior.ironoffercyclesid = re.ironoffercyclesid

		-- Delete from ControlGroupMember_Counts

		DELETE cc FROM nFI.Relational.ControlGroupMember_Counts cc
		INNER JOIN #IronOfferCyclesIDs_ToReset_nFI re
			ON cc.ControlGroupID = re.controlgroupid
		WHERE cc.StartDate BETWEEN @CycleStartDate AND @CycleEndDate; -- Match cycle dates

		-- Delete from SecondaryControlGroups

		DELETE scg FROM nFI.Relational.SecondaryControlGroups scg
		INNER JOIN #IronOfferCyclesIDs_ToReset_nFI re
			ON scg.ironoffercyclesid = re.ironoffercyclesid

		-- Load quereies to drop user Sandbox control member tables

		IF OBJECT_ID('tempdb..#DropTable_Execution_Requests_nFI') IS NOT NULL DROP TABLE #DropTable_Execution_Requests_nFI;

		SELECT
			x.Query
			, ROW_NUMBER() OVER(ORDER BY x.Query) AS RowNum
		INTO #DropTable_Execution_Requests_nFI
		FROM
			(SELECT DISTINCT
				'IF OBJECT_ID('''
				+'Sandbox.'
				+System_User
				+'.Control'
				+CAST(iof.PartnerID AS VARCHAR(4))
				+CONVERT(VARCHAR(10), @CycleStartDate,112)
				+''') IS NOT NULL DROP TABLE '
				++'Sandbox.'
				+System_User
				+'.Control'
				+CAST(iof.PartnerID AS VARCHAR(4))
				+CONVERT(VARCHAR(10), @CycleStartDate,112)
				AS Query
			FROM nFI.Relational.IronOffer iof
			WHERE
				CHARINDEX(',' + CAST(iof.ID AS VARCHAR) + ',', ',' + @IronOfferID + ',') > 0 -- Match input IronOfferIDs
				AND CAST(iof.StartDate AS DATE) <= @CycleEndDate  -- Match cycle dates
				AND (CAST(iof.EndDate AS DATE) >= @CycleStartDate OR iof.EndDate IS NULL)
			) x;

		-- Execute quereies to drop user Sandbox control member tables

		SET @RowNum = 1;
		SET @MaxRow = (SELECT Max(RowNum) From #DropTable_Execution_Requests_nFI);

		WHILE @RowNum <= @MaxRow

		BEGIN
	
			SET @Qry = (SELECT Query FROM #DropTable_Execution_Requests_nFI WHERE RowNum = @RowNum);

			EXEC sp_executeSQL @Qry;

			Set @RowNum = @RowNum +1;
		END

	END 

END