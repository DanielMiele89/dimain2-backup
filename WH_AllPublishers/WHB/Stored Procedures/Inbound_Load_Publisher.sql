
CREATE PROCEDURE [WHB].[Inbound_Load_Publisher]
AS
BEGIN

		SET ANSI_WARNINGS OFF

		SET NOCOUNT ON

	/*******************************************************************************************************************************************
		1.	Clear down [Inbound].[Publisher] table
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Inbound].[Publisher]


	/*******************************************************************************************************************************************
		2.	Load details from [Inbound].[Offer]
	*******************************************************************************************************************************************/
				
		IF OBJECT_ID('tempdb..#Offer') IS NOT NULL DROP TABLE #Offer;
		SELECT	o.PublisherID
			,	o.PublisherType
			,	LiveStatus = MAX(	CASE
										WHEN o.EndDate > GETDATE() THEN 1
										ELSE 0
									END)
		INTO #Offer
		FROM [Inbound].[Offer] o
		GROUP BY	o.PublisherID
				,	o.PublisherType

	/*******************************************************************************************************************************************
		4.	Load [Inbound].[Publisher]
	*******************************************************************************************************************************************/
	
		INSERT INTO [Inbound].[Publisher]	
		SELECT	PublisherID = cl.ID
			,	PublisherName =	CASE
									WHEN cl.Name = 'Karrot' THEN 'Airtime Rewards'
									ELSE cl.Name
								END
			,	PublisherNickname = cl.Nickname
			,	PublisherAbbreviation = cl.Abbreviation
			,	o.PublisherType
			,	LiveStatus = COALESCE(o.LiveStatus, 0)
		FROM [SLC_Report].[dbo].[Club] cl
		LEFT JOIN #Offer o
			ON cl.ID = o.PublisherID
		
		INSERT INTO [dbo].[WarehouseLoadAudit] (ProcName
											,	RunDateTime
											,	RowsInserted)
		SELECT	COALESCE(OBJECT_NAME(@@PROCID), 'Inbound_Load_Publisher - ' + SYSTEM_USER)
			,	GETDATE()
			,	@@ROWCOUNT

END