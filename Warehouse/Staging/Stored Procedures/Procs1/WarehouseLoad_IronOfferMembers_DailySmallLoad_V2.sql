/*

	Author:		Stuart Barnley

	Date:		28th December 2017

	Purpose:	When the number of rows to load is small then this will load them

	Updated:	21st Sept 2018 - RF added Droping & recreation of columnstore index and intergrated the contents of called WarehouseLoad_IronOfferMembers_LoadOldMemberships

*/

CREATE Procedure [Staging].[WarehouseLoad_IronOfferMembers_DailySmallLoad_V2]
--With Execute as Owner 
--With execute recompile
as

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

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

	Declare @Today Date = GetDate()
		  , @Yesterday Date = DateAdd(day,-1,GetDate())
		  , @Weekago Date = DateAdd(day, -7, DateAdd(day, -1, GetDate()))
		  , @Rows Int
		  , @RowCount Int = 0

	Select iof.IronOfferID
	Into #LoadedOffers
	From Relational.IronOffer iof
	Inner Join Iron.OfferProcessLog opl
		on iof.IronOfferID = opl.IronOfferID
	Where opl.ProcessedDate >= @Yesterday

	Create Clustered Index CIX_LoadedOffers_IronOfferID on #LoadedOffers (IronOfferID)

	Set @Rows = (Select Coalesce(Count(*), 0)
				 From #LoadedOffers as lo
				 Inner join Iron.OfferMemberAddition oma
					on lo.IronOfferID = oma.IronOfferID)


	------------------------------------------------------------------------------------------------------------------------
	------------------------------------Find out if validate and commit was used yesterday----------------------------------
	------------------------------------------------------------------------------------------------------------------------

	If @Rows < 950000
	Begin

		-------------------------------------------------------------------------------------------
		---------------------------------Create Table of Customers---------------------------------
		-------------------------------------------------------------------------------------------

			If Object_ID('tempdb..#Customers') Is Not Null Drop Table #Customers
			Select CompositeID
			Into #Customers
			From Relational.Customer

			Create Clustered Index CIX_Customers_CompositeID on #Customers (CompositeID) 
	

		------------------------------------------------------------------------------------
		--------------Create a table of customers activated between date range--------------
		------------------------------------------------------------------------------------

			If Object_ID('tempdb..#NewCustomers') Is Not Null Drop Table #NewCustomers
			Select CompositeID
			Into #NewCustomers
			From Relational.Customer c With (NoLock)
			Where ActivatedDate Between @Weekago and @Yesterday

			Create Clustered Index CIX_Customers_CompositeID on #NewCustomers (CompositeID)


		-------------------------------------------------------------------------------------------
		---------------------------------Find all entries created yesterday------------------------
		-------------------------------------------------------------------------------------------

			Declare @YDay DateTime = @Yesterday
				  , @TDay DateTime = @Today

			If Object_ID('tempdb..#Memberships') Is Not Null Drop Table #Memberships
			Select ioms.IronOfferID
				 , ioms.CompositeID
				 , ioms.StartDate
				 , ioms.EndDate
				 , ioms.ImportDate
			Into #Memberships
			From SLC_report.dbo.IronofferMember ioms With (NoLock)
			Inner join #Customers as c
				on ioms.CompositeID = c.CompositeID
			Where ImportDate >= @YDay
			And ImportDate <  @TDay
			And Not Exists (Select 1
							From Relational.IronOfferMember iomw
							Where ioms.CompositeID = iomw.CompositeID
							And ioms.StartDate = iomw.StartDate
							And ioms.IronOfferID = iomw.IronOfferID)

		-----------------------------------------------------------------------------------
		-------------- Add entries of customers activated between date range --------------
		-----------------------------------------------------------------------------------

			Insert Into #Memberships
			Select ioms.IronOfferID
				 , ioms.CompositeID
				 , ioms.StartDate
				 , ioms.EndDate
				 , ioms.ImportDate
			From #NewCustomers as c
			inner join SLC_report.dbo.IronofferMember ioms With (NoLock)
				on c.CompositeID = ioms.CompositeID
			Where IsControl = 0
			And Not Exists (Select 1
							From #Memberships m
							Where ioms.CompositeID = m.CompositeID
							And ioms.StartDate = m.StartDate
							And ioms.IronOfferID = m.IronOfferID)
			And Not Exists (Select 1
							From Relational.IronOfferMember iomw
							Where ioms.CompositeID = iomw.CompositeID
							And ioms.StartDate = iomw.StartDate
							And ioms.IronOfferID = iomw.IronOfferID)

			Create Clustered Index CIX_MS_CompositeID_IronOfferID_StartDate on #Memberships (StartDate, IronOfferID, CompositeID)


		------------------------------------------------------------------------------------------------------------------------
		-------------------------------------------------Drop columnstore Index-------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------

			DROP INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember]

		-------------------------------------------------------------------------------------------
		------------------------------Insert entries into relational table-------------------------
		-------------------------------------------------------------------------------------------

			Insert into relational.IronOfferMember
			Select IronOfferID
				 , CompositeID
				 , StartDate
				 , EndDate
				 , ImportDate
			From #Memberships m
			Set @RowCount = @@ROWCOUNT

		------------------------------------------------------------------------------------------------------------------------
		------------------------------------------------Create columnstore Index------------------------------------------------
		------------------------------------------------------------------------------------------------------------------------

			CREATE NONCLUSTERED COLUMNSTORE INDEX [CSX_IronOfferMember_All] ON [Relational].[IronOfferMember] ([IronOfferID], [CompositeID], [StartDate], [EndDate], [ImportDate])

	End	--	@Rows < 950000


		--	Queries executed in the below sProc have been integrated above
		--if @Rows < 950000 
		--Begin
		--	Declare @Weekago date = Dateadd(day,-7,@Yesterday)
		--	EXEC Staging.WarehouseLoad_IronOfferMembers_LoadOldMemberships @Weekago, @Yesterday
		--End	--	@Rows < 950000 


	If @Rows >= 950000
	Begin
		Declare @Body nVarChar(Max) = '<font face="Calibri">Dear Campaign Operations,<br>
		<br>
		Due to the number of rows added to the live system yesterday they have not been imported as part of the daily load.<br><br>
		Please run the bulk upload stored as follows:<br><br><b><i>
	
		Declare @Yesterday Date = DateAdd(Day, -1 , GetDate())<br>
		Select @Yesterday<br><br>

		Exec warehouse.Staging.WarehouseLoad_IronOfferMembers_DailyBulkLoad @Yesterday <br><br></b></i>
	
		Please warn people before running as this process disables indexes on Warehouse.Relational.IronofferMember while loading, then rebuilds<br><br>'

		Exec msdb..sp_send_dbmail @profile_name = 'Administrator'
								, @recipients = 'Campaign.Operations@rewardinsight.com'
								, @subject = 'MyRewards - Warehouse.Relational.IronOfferMember Loading Situation'
								, @execute_query_database = 'Warehouse'
								, @body = @body
								, @body_format = 'HTML'
								, @importance = 'HIGH'
	End	--	@Rows >= 950000

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
		

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run