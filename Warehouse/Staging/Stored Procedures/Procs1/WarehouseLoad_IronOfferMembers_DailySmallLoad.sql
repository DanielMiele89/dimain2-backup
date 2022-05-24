/*

	Author:		Stuart Barnley

	Date:		28th December 2017

	Purpose:	When the number of rows to load is small then this will load them

	Updated:	21st Sept 2018 - RF added Droping & recreation of columnstore index

*/

CREATE Procedure [Staging].[WarehouseLoad_IronOfferMembers_DailySmallLoad]
With Execute as Owner 
--With execute recompile
as

------------------------------------------------------------------------------------------------------------------------
----------------------------------------Write entry to JobLog_Temp Table------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailySmallLoad',
		TableSchemaName = 'Relational',
		TableName = 'IronofferMember',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'A'

------------------------------------------------------------------------------------------------------------------------
------------------------------------Find out if validate and commit was used yesterday----------------------------------
------------------------------------------------------------------------------------------------------------------------

Declare @Yesterday Date = Dateadd(day,-1,getdate()),
		@Today date = getdate(),
		@Rows int,
		@RowCount int = 0


Select i.IronOfferID
Into #LoadedOffers
From Relational.IronOffer as i
inner Join Iron.OfferProcessLog as opl
	on i.IronOfferID = opl.IronOfferID
Where opl.ProcessedDate >= @Yesterday

Create Clustered Index cix_LoadedOffers_IronOfferID on #LoadedOffers(IronOfferID)

Set @Rows = (	Select coalesce(Count(*),0)
				From #LoadedOffers as lo
				inner join Iron.OfferMemberAddition as oma
					on lo.IronOfferID = oma.IronOfferID
			)

If @Rows > 0
Begin 

	------------------------------------------------------------------------------------------------------------------------
	------------------------------------Find out if validate and commit was used yesterday----------------------------------
	------------------------------------------------------------------------------------------------------------------------

	If @Rows < 950000
	Begin
		-------------------------------------------------------------------------------------------
		---------------------------------Create Table of Customers---------------------------------
		-------------------------------------------------------------------------------------------
		if object_id('tempdb..#Customers') is not null drop table #Customers
		Select CompositeID
		Into #Customers
		From warehouse.relational.customer

		Create clustered index cix_Customers_CompositeID on #Customers (CompositeID) 

		-------------------------------------------------------------------------------------------
		---------------------------------Find all entries created yesterday------------------------
		-------------------------------------------------------------------------------------------
		Declare @YDay datetime = @Yesterday,
				@TDay datetime = @Today

	
		if object_id('tempdb..#Memberships') is not null drop table #Memberships
		Select iom.*
		Into #Memberships
		From slc_report.dbo.ironoffermember  as iom
		inner join #Customers as c
				on iom.CompositeID = c.CompositeID
		where ImportDate >= @YDay and 
			  ImportDate <  @TDay

		Create clustered index cix_MS_CompositeID_IronOfferID_StartDate 
											on #Memberships (CompositeID,IronOfferID,StartDate)

		------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------Drop columnstore Index-------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------

		DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

		-------------------------------------------------------------------------------------------
		-------------------------Remove entries already in Relational table------------------------
		-------------------------------------------------------------------------------------------

		Delete From m
		From warehouse.relational.ironoffermember as iom
			inner join #Memberships as m
			on	iom.CompositeID = m.COmpositeID and
				iom.IronofferID = m.IronOfferID and
				iom.StartDate = m.StartDate

		-------------------------------------------------------------------------------------------
		------------------------------Insert entries into relational table-------------------------
		-------------------------------------------------------------------------------------------

		Insert into warehouse.relational.IronOfferMember
		Select	IronOfferID,
				CompositeID,
				StartDate,
				EndDate,
				ImportDate
		From #Memberships as m
		Set @RowCount = @@ROWCOUNT

	End	--	@Rows < 950000

	if @Rows < 950000 
	Begin
		Declare @Weekago date = Dateadd(day,-7,@Yesterday)
		EXEC Staging.WarehouseLoad_IronOfferMembers_LoadOldMemberships @Weekago, @Yesterday
	

	------------------------------------------------------------------------------------------------------------------------
	------------------------------------------------Create columnstore Index------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------

		CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])
	
	End	--	@Rows < 950000 


	If @Rows >= 950000
	Begin
			Declare @Body nvarchar(max) = '<font face="Calibri">Dear Campaign Operations,<br>
			<br>
			Due to the number of rows added to the live system yesterday they have not been imported as part of the daily load.<br><br>
			Please run the bulk upload stored as follows:<br><br><b><i>
		
			Declare @Yesterday Date = DateAdd(Day, -1 , GetDate())<br>
			Select @Yesterday<br><br>

			Exec warehouse.Staging.WarehouseLoad_IronOfferMembers_DailyBulkLoad @Yesterday <br><br></b></i>
		
			Please warn people before running as this process disables indexes on Warehouse.Relational.IronofferMember while loading, then rebuilds<br><br>'

		exec msdb..sp_send_dbmail 
			 @profile_name = 'Administrator',
			 @recipients= 'Campaign.Operations@rewardinsight.com',
	 		 @subject = 'MyRewards - Warehouse.Relational.IronOfferMember Loading Situation',
	 		 @execute_query_database = 'Warehouse',
			 @body= @body,
			 @body_format = 'HTML', 
	 		 @importance = 'HIGH'
	End	--	@Rows >= 950000


End	--	@Rows > 0

------------------------------------------------------------------------------------------------------------------------
------------------------------------Update entry in JobLog_Temp Table with End Date-------------------------------------
------------------------------------------------------------------------------------------------------------------------
UPDATE staging.JobLog_Temp
SET		EndDate = GETDATE(),
		TableRowCount = @RowCount
WHERE	StoredProcedureName = 'WarehouseLoad_IronOfferMembers_DailySmallLoad' 
	AND TableSchemaName = 'Relational'
	AND TableName = 'IronofferMember' 
	AND EndDate IS NULL

------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------Insert entry into JobLog----------------------------------------------
------------------------------------------------------------------------------------------------------------------------
Insert into staging.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from staging.JobLog_Temp

truncate table staging.JobLog_Temp

