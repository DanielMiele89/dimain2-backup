
/******************************************************************************
PROCESS NAME: Offer Calculation - Maintenance - Update OfferName Hierarchy Table

Author	  Hayden Reid
Created	  31/01/2017
Purpose	  Inserts missing clubs into OfferNameHierarchy table

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [Report].[OfferReport_Insert_OfferNameHierarchy] 
	
AS
BEGIN
	SET NOCOUNT ON;   
	
    IF OBJECT_ID('tempdb..#Clubs') IS NOT NULL DROP TABLE #Clubs
    SELECT	DISTINCT
			PublisherID
		,	DENSE_RANK() OVER(ORDER BY PublisherID) RwID
    INTO #Clubs
    FROM [Report].[OfferReport_OfferReportingPeriods] ior
    WHERE NOT EXISTS (	SELECT 1
						FROM [Report].[OfferReport_OfferNameHierarchy] onh
						WHERE onh.PublisherID = ior.PublisherID)

    DECLARE @maxID INT = (SELECT MAX(RwID) FROM #Clubs)

    ;WITH
	IDs AS (SELECT	1 rwID
			,		(SELECT MAX(Ordinal) FROM [Report].[OfferReport_OfferNameHierarchy])+1 ID
			UNION ALL
			SELECT	rwID + 1
				,	ID + 1
			FROM IDs
			WHERE rwID < @maxID)

    INSERT INTO [Report].[OfferReport_OfferNameHierarchy]
    SELECT	PublisherID
		,	i.ID 
    FROM #Clubs c
    INNER JOIN IDs i
		ON i.rwID = c.RwID


END