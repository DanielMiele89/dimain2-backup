
/********************************************************************************************
** Name: Staging.nFIPartnerDeals_Validation
** Desc: To run a SET of validation rules against the Partner Deals imported data
** Auth: Zoe Taylor
** Date: 02/05/2017
*********************************************************************************************
** Change History
** ---------------------
** 2017-05-02 Zoe Taylor
**                           Creation of script
**
** [date] [user]
**                           [description of change]   
**
**
** Notes
** --------------------
** Error logging inserts ID's in to the table - error messages can be found in 
** Relational.nFIPartnerDeals_ErrorType
**
*********************************************************************************************/

CREATE Procedure [Staging].[nFIPartnerDeals_Validation]
With Execute as Owner
as
BEGIN


Declare @ID int = 0
, @EmailMessage varchar(max) = ''
, @EmailSubject varchar(max) = ''

/******************************************************************
                                                
    Truncate errors table
                
******************************************************************/

TRUNCATE TABLE [Staging].[nFIPartnerDeals_Errors_V2]

-------------------------------------------------------------------
--                             Remove NULL ID's
-------------------------------------------------------------------

DELETE
FROM [Staging].[nFIPartnerDeals_Holding_V2]
WHERE ID IS NULL
OR (PartnerID = 4451 AND ClubID = 12)


/******************************************************************
                                                
    Cast columns in to correct format to validate 
                
******************************************************************/
                
	IF OBJECT_ID('tempdb..#DataToCheck') IS NOT NULL DROP TABLE #DataToCheck
	SELECT	[ID] = CAST(h.ID AS REAL)
		,	[ClubID] = CAST(h.ClubID AS REAL)
		,	[PartnerID] = CAST(h.PartnerID AS REAL)
		,	[ManagedBy] = CAST(h.ManagedBy AS VARCHAR(100))
		,	[StartDate] = CAST(h.StartDate AS DATE)
		,	[EndDate] = CAST(h.EndDate AS DATE)
		,	[Override] = CAST(CAST(h.Override AS FLOAT) AS DECIMAL(5,2))
		,	[Publisher] = CAST(CAST(h.Publisher AS FLOAT)*100 AS DECIMAL(5,2))
		,	[Reward] = CAST(CAST(h.Reward AS FLOAT)*100 AS DECIMAL(5,2))
		,	[FixedOverride] = CAST(h.FixedOverride AS BIT)
	INTO #DataToCheck
	FROM [Staging].[nFIPartnerDeals_Holding_V2] h

	CREATE CLUSTERED INDEX idx_DataToCheck_ID on #DataToCheck(ID)

/******************************************************************
                                                                
                    Data manipulation 
                                
******************************************************************/      

    -------------------------------------------------------------------
    --                             Remove blanks AND replace with NULLS
    -------------------------------------------------------------------
                
		UPDATE #DataToCheck
		SET ManagedBy = NULL
		WHERE ManagedBy = ''

    -------------------------------------------------------------------
    --                             Replace description with ID numbers
    -------------------------------------------------------------------
                                                
		UPDATE x
		SET ManagedBy = y.ID
		FROM #DataToCheck x
		LEFT JOIN [Relational].[nFIPartnerDeals_Relationship_V2]  y
			ON x.ManagedBy = y.Description
                                                
/******************************************************************
                                                
    BEGIN Validation checks 
                
******************************************************************/

/******************************************************************
                                                                
                    Check for duplicates 
                                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#DupesCheck') IS NOT NULL DROP TABLE #DupesCheck;
	WITH
	Dupes AS (	SELECT	x.PartnerID
					,	x.ClubID
                FROM #DataToCheck x
                WHERE EndDate IS NULL
                GROUP BY x.PartnerID, x.ClubID
                HAVING COUNT(1) > 1)

    SELECT	DISTINCT
			dtc.ID
		,	d.PartnerID
		,	d.ClubID
    INTO #DupesCheck
    FROM #DataToCheck dtc
    INNER JOIN Dupes d
		ON dtc.PartneriD = d.PartnerID 
		AND dtc.ClubID = d.clubid
    WHERE dtc.EndDate IS NULL
    AND dtc.ID IS NOT NULL

    IF (@@ROWCOUNT <> 0) 
    BEGIN
		INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
		SELECT	ID
			,	1
		FROM #DupesCheck
    END

    DROP TABLE #DupesCheck
                
/******************************************************************
                                                
                    Check all PartnerID's exist 
                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#PartnerCheck') IS NOT NULL DROP TABLE #PartnerCheck
    SELECT	DISTINCT
			dtc.ID
		,	dtc.PartnerID
    INTO #PartnerCheck
    FROM #DataToCheck dtc
	WHERE NOT EXISTS (	SELECT 1
						FROM [SLC_Report].[dbo].[Partner] pa
						WHERE dtc.PartnerID = pa.ID)

    If (@@ROWCOUNT <> 0) 
    BEGIN
		INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
		SELECT	ID
			,	2
		FROM #PartnerCheck
    END

    DROP TABLE #PartnerCheck           
                
/******************************************************************
                                                
                    Check all ClubID's exist 
                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#ClubCheck') IS NOT NULL DROP TABLE #ClubCheck
    SELECT	DISTINCT
			dtc.ID
		,	dtc.ClubID
		,	ISNULL(c.ClubID, 132) [ClubIDCheck]
    INTO #ClubCheck
    FROM #DataToCheck dtc
    LEFT JOIN nFI.Relational.Club c
		ON c.ClubID = dtc.ClubID
    WHERE ISNULL(c.ClubID, 132) IS NULL

    If (@@ROWCOUNT <> 0) 
    BEGIN
		INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
		SELECT	ID
			,	3
		FROM #ClubCheck
    End                        
                                
    DROP TABLE #ClubCheck

/******************************************************************
                                                
                    Check ManagedBy column is valid 
                
******************************************************************/
                                
    -------------------------------------------------------------------
    --                             BEGIN checking
    -------------------------------------------------------------------
                
    IF OBJECT_ID('tempdb..#ManagedByCheck') IS NOT NULL DROP TABLE #ManagedByCheck
    SELECT DISTINCT x.ID
                    , x.ManagedBy
                    , r.Description                    
    INTO #ManagedByCheck
    FROM #DataToCheck x
    LEFT JOIN Relational.nFIPartnerDeals_Relationship_V2 r
                    on r.ID = x.managedby
    WHERE x.ManagedBy IS NOT NULL AND r.Description IS NULL
                                                
    If (@@ROWCOUNT <> 0) 
    BEGIN
    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
                    SELECT ID, 4
                    FROM #ManagedByCheck             
    End
                                
    DROP TABLE #ManagedByCheck

/******************************************************************
                                                                
                    Check FixedOverride column is 1 or 0
                                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#FixedOverrideCheck') IS NOT NULL DROP TABLE #FixedOverrideCheck
    SELECT DISTINCT x.ID
                    , x.FixedOverride                             
    INTO #FixedOverrideCheck
    FROM #DataToCheck x
    WHERE FixedOverride not in (0, 1)
                                                
    If (@@ROWCOUNT <> 0) 
    BEGIN
    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2] (RowID, ErrorID)
                    SELECT ID, 5
                    FROM #FixedOverrideCheck
    End

    DROP TABLE #FixedOverrideCheck                              
                                
/******************************************************************
                                                                
                    Check Publisher + Reward = 100
                                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#RewardPublisherSumCheck') IS NOT NULL DROP TABLE #RewardPublisherSumCheck
    SELECT x.ID
                    , x.Publisher
                    , x.Reward
                    , x.Publisher + x.Reward [Sum]
    INTO #RewardPublisherSumCheck
    FROM #DataToCheck x
    WHERE x.Publisher + x.Reward not in (100, 0)                                                       
                                                
    If (@@ROWCOUNT <> 0) 
    BEGIN
    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2] (RowID, ErrorID)
                    SELECT ID, 6
                    FROM #RewardPublisherSumCheck
    End

    DROP TABLE #RewardPublisherSumCheck

    /******************************************************************
                                                                                
                                    Date checks 
                                                
    ******************************************************************/
                -------------------------------------------------------------------
                --                             Check only one row per partner/publisher combination 
                --                             without an end date (i.e. the row is current)
                -------------------------------------------------------------------
                                                                                
                IF OBJECT_ID('tempdb..#CurrentRowCheck') IS NOT NULL DROP TABLE #CurrentRowCheck
                SELECT DISTINCT x.PartnerID
                                , x.ClubID
                                , EndDate            
                INTO #CurrentRowCheck
                FROM #DataToCheck x
                WHERE EndDate IS NULL
                GROUP BY x.PartnerID, x.ClubID, EndDate
                Having COUNT(1) > 1
                                                                                

                If (@@ROWCOUNT <> 0) 
                BEGIN                     
                -------------------------------------------------------------------
                --                             Only insert errors if the "duplicate row" check has passed,
                --                             otherwise the same row will insert different errors
                -------------------------------------------------------------------                                                                                                                           
                    If (
                                                SELECT COUNT(distinct x.ID) 
                                                    FROM #CurrentRowCheck y
                                                LEFT JOIN #DataToCheck z
                                                                on z.partnerid = y.partnerid
                                                                AND z.clubid = y.clubid
                                                LEFT JOIN [Staging].[nFIPartnerDeals_Errors_V2] x
                                                                on x.RowID = z.ID
                                                                AND x.ErrorID = 1 ) = 0
                                BEGIN
                                                                INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2] (RowID, ErrorID)
                                                                SELECT x.ID, 7
                                                                FROM #CurrentRowCheck y
                                                                inner Join #DataToCheck x
                                                                                on y.partnerid = x.partnerid
                                                                                AND y.clubid = x.clubid
                                End
End

                    DROP TABLE #CurrentRowCheck

                    -------------------------------------------------------------------
                    --                             Check StartDate is before EndDate
                    -------------------------------------------------------------------

                    IF OBJECT_ID('tempdb..#StartDateCheck') IS NOT NULL DROP TABLE #StartDateCheck
                    SELECT DISTINCT x.ID
                                    , x.StartDate
                                    , x.EndDate         
                    INTO #StartDateCheck
                    FROM #DataToCheck x
                    WHERE EndDate < StartDate
                                                                                                                                                                                
                    If (@@ROWCOUNT <> 0) 
                    BEGIN
                                    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2] (RowID, ErrorID)
                                    SELECT x.ID, 8
                                    FROM #StartDateCheck x
                    End

                    DROP TABLE #StartDateCheck
                                                                
                    -------------------------------------------------------------------
                    --                             Check Previous EndDate is before next StartDate
                    -------------------------------------------------------------------

                    IF OBJECT_ID('tempdb..#PreviousDateCheck') IS NOT NULL DROP TABLE #PreviousDateCheck
                    SELECT ID, StartDate, EndDate, PreviousEndDate
                    INTO #PreviousDateCheck
                    FROM (
                                    SELECT *
                                                    , LAG(x.EndDate, 1, NULL) OVER(PARTITION by PartnerID, ClubID order by PartnerID, ClubID, StartDate) PreviousEndDate
                                    FROM #DatatoCheck x
                    ) y
                    WHERE y.PreviousEndDate >= y.StartDate
                                                                                                                                                                                
                    If (@@ROWCOUNT <> 0) 
                    BEGIN
                                    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2] (RowID, ErrorID)
                                    SELECT x.ID, 9
                                    FROM #PreviousDateCheck x
                    End

                    DROP TABLE #PreviousDateCheck
                                                
/******************************************************************
                                                                
                    Check for secondary partner records 
                                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#SecondaryRecords') IS NOT NULL DROP TABLE #SecondaryRecords
    SELECT x.ID, x.PartnerID
    INTO #SecondaryRecords
    FROM #DataToCheck x
    LEFT JOIN Warehouse.APW.partneralternate p
                    on p.PartnerID = x.PartnerID
    WHERE p.PartnerID IS NOT NULL
	AND p.PartnerID != 4790

                                                
    If (@@ROWCOUNT <> 0) 
    BEGIN
                    INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
                    SELECT ID, 10
                    FROM #SecondaryRecords
    End

    DROP TABLE #SecondaryRecords

/******************************************************************
                                                                
                    Check for data that has changed since last import 
                                
******************************************************************/
                                
    IF OBJECT_ID('tempdb..#ModificationCheck') IS NOT NULL DROP TABLE #ModificationCheck
    SELECT x.ID
    INTO #ModificationCheck
    FROM #DataToCheck x
    Join [Relational].[nFI_Partner_Deals] n
                    on x.ID = n.ID                                     
    WHERE x.EndDate IS NOT NULL
                                
    IF OBJECT_ID('tempdb..#ModCheck') IS NOT NULL DROP TABLE #ModCheck
    SELECT ID 
    INTO #ModCheck
    FROM (
                    SELECT * 
                    FROM [Relational].[nFI_Partner_Deals] 
                                    Except
                    SELECT * 
                    FROM #DataToCheck
    ) y
    WHERE ID in (SELECT ID FROM #ModificationCheck)

    --If (@@ROWCOUNT <> 0) 
    --                BEGIN
    --                               -- INSERT INTO [Staging].[nFIPartnerDeals_Errors_V2](RowID, ErrorID)
    --                                SELECT ID, 11
    --                                FROM #ModCheck
				--	 End

    DROP TABLE #ModCheck
    DROP TABLE #ModificationCheck

/******************************************************************
                                                                
                    If validation success, insert Data in to main table AND 
                    truncate holding table 
                                
******************************************************************/

-------------------------------------------------------------------
--                             Check if there are NO errors
-------------------------------------------------------------------
                                                
    If (SELECT COUNT(1) FROM [Staging].[nFIPartnerDeals_Errors_V2]) = 0
    BEGIN                                     
                                                
    -------------------------------------------------------------------
    --                             Truncate old data
    -------------------------------------------------------------------
                                                
                    TRUNCATE TABLE [Relational].[nFI_Partner_Deals]
                    TRUNCATE TABLE [WH_AllPublishers].[Derived].[RetailerCommercialTerms]

    -------------------------------------------------------------------
    --                             Insert new data
    -------------------------------------------------------------------
	
                    INSERT INTO [Relational].[nFI_Partner_Deals]
                    SELECT * 
                    FROM #DataToCheck
	
                    INSERT INTO [WH_AllPublishers].[Derived].[RetailerCommercialTerms]
                    SELECT * 
                    FROM #DataToCheck

    -------------------------------------------------------------------
    --                             Truncate holding table
    -------------------------------------------------------------------
                                                
                    TRUNCATE TABLE Staging.nFIPartnerDeals_Holding_V2

    -------------------------------------------------------------------
    --                             Send success email
    -------------------------------------------------------------------                                                           
                                                                                
                    SET @EmailMessage = 'Notification email: The Partner Deals ETL import has completed sucessfully.'
                    SET @EmailSubject = 'Partner Deals ETL Success'

                    Exec msdb..sp_send_dbmail 
                                    @profile_name = 'Administrator', 
                                    @recipients='DataOperations@rewardinsight.com',
                                    @subject = @EmailSubject,
                                    @body= @EmailMessage,
                                    @body_format = 'HTML', 
                                    @importance = 'Normal', 
                                    @exclude_query_output = 1
    End

/******************************************************************
                                                                
                    If failure, Send error email
                                
******************************************************************/
                                
-------------------------------------------------------------------
--                             Check for errors
-------------------------------------------------------------------
                                
If (SELECT COUNT(1) FROM [Staging].[nFIPartnerDeals_Errors_V2]) > 0
BEGIN

-------------------------------------------------------------------
--                             Truncate main table
-------------------------------------------------------------------
                                
TRUNCATE TABLE Staging.nFIPartnerDeals_Holding_V2

-------------------------------------------------------------------
--                             Truncate report table AND insert new data
-------------------------------------------------------------------
                                                                                
    TRUNCATE TABLE Staging.R_0154_PartnerDealsErrorReport

    INSERT INTO Staging.R_0154_PartnerDealsErrorReport(
                                                    ErrorID
                                                    , Message
                                                    , columntocheck
                                                    , ID
                                                    , ClubID
                                                    , ClubName
                                                    , PartnerID
                                                    , PartnerName
                                                    , ManagedBy
                                                    , StartDate
                                                    , EndDate
                                                    , Override
                                                    , Publisher
                                                    , Reward
                                                    , FixedOverride) 
    SELECT y.ErrorID
                    , e.message
                    , e.columntocheck
                    , x.ID
                    , x.ClubID [ClubName]
                    , c.Name
                    , x.PartnerID [PartnerName]
                    , p.Name
                    , x.ManagedBy
                    , x.StartDate
                    , x.EndDate
                    , x.Override
                    , x.Publisher
                    , x.Reward
                    , x.FixedOverride
    FROM [Staging].[nFIPartnerDeals_Errors_V2] y
    Inner Join Relational.nFIPartnerDeals_ErrorType e
                    on e.errorid = y.errorid
    LEFT JOIN #DataToCheck x
                    on x.ID = y.RowID
    LEFT JOIN SLC_Report.dbo.club c
                    on c.id = x.clubid
    LEFT JOIN slc_report.dbo.Partner p
                    on p.ID = x.partnerid

-------------------------------------------------------------------
--                             Send error report via SSRS subscription
-------------------------------------------------------------------
                                
    Exec ReportServer.dbo.AddEvent @EventType='TimedSubscription',@EventData='5d24142e-6bd9-48a2-ac75-b8aee3100088'

End
                                
End