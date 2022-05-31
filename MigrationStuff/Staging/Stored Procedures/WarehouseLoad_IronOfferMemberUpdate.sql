/*

	Author:		Stuart Barnley

	Purpose:	Created to add enddates to IronOfferMember entries in relational.IronOfferMember
				when they have been added on live. This is only run weekly as updated records are
				only copied over weekly.
				
*/
CREATE Procedure [Staging].[WarehouseLoad_IronOfferMemberUpdate] 
--with Execute as Owner
As

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMemberUpdate',
		TableSchemaName = 'Relational',
		TableName = 'IronOfferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'C'

/*--------------------------------------------------------------------------------------------------
------------------------------------Declare Variables-----------------------------------------------
----------------------------------------------------------------------------------------------------*/

	DECLARE @LastWeek DATE

	SET @LastWeek = DATEADD(DAY, -7, GETDATE())

--------------------------------------------------------------------------------------------------------
-----------------------Find offers that were/are live and may have updated members----------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#IronOffer') IS NOT NULL DROP TABLE #IronOffer
	SELECT	iof.ID as IronOfferID
	INTO #IronOffer
	FROM [Relational].[IronOffer] iof
	WHERE EndDate IS NULL 
	OR @LastWeek <= EndDate

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IronOffer (IronOfferID)

--------------------------------------------------------------------------------------------------------
--------------------------Prepare to review IOM table to look for End Dated records---------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#IOM_SLC') IS NOT NULL DROP TABLE #IOM_SLC
	SELECT	iom.IronOfferID
		,	cu.FanID
		,	iom.StartDate
		,	iom.EndDate
	INTO #IOM_SLC
	FROM [SLC_Report].[dbo].[IronOfferMember] iom
	INNER JOIN [Relational].[Customer] cu
		ON iom.CompositeID = cu.CompositeID
	WHERE @LastWeek <= iom.EndDate
	AND EXISTS (	SELECT 1
					FROM #IronOffer iof
					WHERE iom.IronOfferID = iom.IronOfferID)

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IOM_SLC (IronOfferID, FanID, StartDate)

--------------------------------------------------------------------------------------------------------
--------------------------Prepare to review IOM table to look for End Dated records---------------------
--------------------------------------------------------------------------------------------------------

	IF OBJECT_ID('tempdb..#IOM_Warehouse') IS NOT NULL DROP TABLE #IOM_Warehouse
	SELECT	iomw.IronOfferID
		,	iomw.FanID
		,	iomw.StartDate
		,	iomw.EndDate
	INTO #IOM_Warehouse
	FROM [Relational].[IronOfferMember] iomw
	WHERE iomw.EndDate IS NULL
	AND EXISTS (	SELECT 1
					FROM #IOM_SLC ioms
					WHERE iomw.IronOfferID = ioms.IronOfferID
					AND iomw.FanID = ioms.FanID
					AND iomw.StartDate = ioms.StartDate)

	CREATE CLUSTERED INDEX CIX_IronOfferID ON #IOM_Warehouse (IronOfferID, FanID, StartDate, EndDate)

--------------------------------------------------------------------------------------------------------
---------------------------------------------Update members---------------------------------------------
--------------------------------------------------------------------------------------------------------

	UPDATE iom
	SET iom.EndDate = u.EndDate
	FROM #IOM_Warehouse u
	INNER JOIN [Relational].[IronOfferMember] iom
		ON u.FanID = iom.FanID
		AND u.IronOfferID = iom.IronOfferID
		AND u.StartDate = iom.StartDate
	WHERE iom.EndDate IS NULL

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_IronOfferMemberUpdate' and
		TableSchemaName = 'Relational' and
		TableName = 'IronOfferMember' and
		EndDate is null

-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

TRUNCATE TABLE staging.JobLog_Temp