
/*
Author:		Rory Francis
Date:		9 June 2018
Purpose:	Maintain table used to keep track of MIDs being incentivised on MyRewards

Notes:		
*/

CREATE PROCEDURE [WHB].[__Partners_MIDTrackingGAS_Archived]
as
	Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

	BEGIN TRY

	--------------------------------------------------------------------------------------------------------------------
	-------------------------------------   Declare variable to update End Dates   -------------------------------------
	--------------------------------------------------------------------------------------------------------------------

	Declare @EndDate Date = GETDATE()
	Declare @MatchDate Date = DATEADD(day,-1,@EndDate)

	--------------------------------------------------------------------------------------------------------------------
	-----------------------   Fetch all new entries to the Match table and ConsumerCombination   -----------------------
	--------------------------------------------------------------------------------------------------------------------

	If OBJECT_ID ('Tempdb..#SLC_Report_Match') Is Not Null Drop Table #SLC_Report_Match
	Select Distinct
		   [SLC_Report].[dbo].[Match].[MerchantID]
		 , [SLC_Report].[dbo].[Match].[RetailOutletID]
	Into #SLC_Report_Match
	From SLC_Report..Match
	Where [SLC_Report].[dbo].[Match].[AddedDate] >= @MatchDate

	Create Index CIX_SLCReportMatch_RetailOutletMID On #SLC_Report_Match (MerchantID, RetailOutletID)

	----------------------------------------------------------------------------------------------------------------------
	-----------------------------------------   Write entry to JobLog Temp table   ---------------------------------------
	----------------------------------------------------------------------------------------------------------------------

	--	Insert into staging.JobLog_Temp
	--	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
	--			TableSchemaName = 'Relational',
	--			TableName = 'MIDTrackingGAS',
	--			StartDate = GETDATE(),
	--			EndDate = null,
	--			TableRowCount  = null,
	--			AppendReload = 'U'

	--------------------------------------------------------------------------------------------------------------------
	-----------------------------   Update any MIDs after first appearance in CC or Match   ----------------------------
	--------------------------------------------------------------------------------------------------------------------

		-------------------------------------------------------------------------------------
		---------------------   Fetch all MIDs where MID_Join is null   ---------------------
		-------------------------------------------------------------------------------------

			If OBJECT_ID ('Tempdb..#MissingMID_Join') Is Not Null Drop Table #MissingMID_Join
			Select *
			Into #MissingMID_Join
			From Relational.MIDTrackingGAS mtg
			Where [Relational].[MIDTrackingGAS].[MID_Join] is null

		-------------------------------------------------------------------------------------
		----------------------   Join to Match & CC to find MID_Join   ----------------------
		-------------------------------------------------------------------------------------

			If OBJECT_ID('Tempdb..#MissingMID_JoinWithData') Is Not Null Drop Table #MissingMID_JoinWithData;
			With
				NewOutletsInCC as (
					Select mmcc.RetailOutletID
						 , mmcc.PartnerID
						 , mmcc.MID_GAS
						 , #MissingMID_Join.[cc].MID as MID_Join
						 , mmcc.StartDate
						 , Convert(Date,Null) as EndDate
					From #MissingMID_Join mmcc
					Inner Join Relational.ConsumerCombination cc
						on #MissingMID_Join.[cc].MID=mmcc.MID_GAS),
						
				NewOutletsInCCLeadingZero as (
					Select mmcc.RetailOutletID
						 , mmcc.PartnerID
						 , mmcc.MID_GAS
						 , #MissingMID_Join.[cc].MID as MID_Join
						 , mmcc.StartDate
						 , Convert(Date,Null) as EndDate
					From #MissingMID_Join mmcc
					Inner Join Relational.ConsumerCombination cc
						on '0'+#MissingMID_Join.[cc].MID=mmcc.MID_GAS
					Where LEN(#MissingMID_Join.[cc].MID) = 7),
						
				NewOutletsInMatch as (
					Select mmcc.RetailOutletID
						 , mmcc.PartnerID
						 , mmcc.MID_GAS
						 , ma.MerchantID as MID_Join
						 , mmcc.StartDate
						 , Convert(Date,Null) as EndDate
					From #MissingMID_Join mmcc
					Inner Join #SLC_Report_Match ma
						on ma.RetailOutletID=mmcc.RetailOutletID
						and ma.MerchantID like '%' + mmcc.MID_GAS)

			Select Distinct
					RetailOutletID
				  , #MissingMID_Join.[cc] as MID_Join_New
			Into #MissingMID_JoinWithData
			From (
				Select * From NewOutletsInCC
				Union
				Select * From NewOutletsInCCLeadingZero
				Union
				Select * From NewOutletsInMatch) no

		-------------------------------------------------------------------------------------
		----------------  UPDATE MID_Join with new values   ----------------
		-------------------------------------------------------------------------------------

			Update Relational.MIDTrackingGAS
			Set [Relational].[MIDTrackingGAS].[MID_Join] = [mmccwd].[MID_Join_New]
			From Relational.MIDTrackingGAS mtg
			Inner Join #MissingMID_JoinWithData mmccwd
				on #MissingMID_JoinWithData.[mtg].RetailOutletID=mmccwd.RetailOutletID
			Where #MissingMID_JoinWithData.[mtg].MID_Join Is Null;

	--------------------------------------------------------------------------------------------------------------------
	-------------------------------------   Update any MIDs that have been hashed   ------------------------------------
	--------------------------------------------------------------------------------------------------------------------

		-------------------------------------------------------------------------------------
		--------------------   Look for any MIDs that have been hashed   --------------------
		-------------------------------------------------------------------------------------

			If OBJECT_ID ('Tempdb..#HashedMIDs') Is Not Null Drop Table #HashedMIDs
			Select ro.ID RetailOutletID
				 , [SLC_Report].[dbo].[RetailOutlet].[MerchantID] as MID_GAS_New
			Into #HashedMIDs
			From SLC_Report..RetailOutlet ro
			Where ([SLC_Report].[dbo].[RetailOutlet].[MerchantID] Like '#%' Or [SLC_Report].[dbo].[RetailOutlet].[MerchantID] Like 'x%' Or [SLC_Report].[dbo].[RetailOutlet].[MerchantID] Like 'ARCHIVED-%')
			And not exists (Select 1
							From Relational.MIDTrackingGAS mtg
							Where ro.MerchantID = mtg.MID_GAS
							And ro.ID = mtg.RetailOutletID);						--	And ro.ID = mtg.RetailOutletID added 2018-09-24 RF
				
		-------------------------------------------------------------------------------------
		----------------  UPDATE MID_GAS with new hashed value and EndDate   ----------------
		-------------------------------------------------------------------------------------
	
			Update mtg
			Set [Relational].[MIDTrackingGAS].[MID_GAS] = [hm].[MID_GAS_New]
			  , [Relational].[MIDTrackingGAS].[EndDate] = @EndDate
			From Relational.MIDTrackingGAS mtg
			Inner Join #HashedMIDs hm
				on #HashedMIDs.[mtg].RetailOutletID=hm.RetailOutletID
			Where #HashedMIDs.[mtg].EndDate Is Null;


	--------------------------------------------------------------------------------------------------------------------
	-------------------------------------   Update any MIDs that have been unhashed   ------------------------------------
	--------------------------------------------------------------------------------------------------------------------

		-------------------------------------------------------------------------------------
		--------------------   Look for any MIDs that have been unhashed   --------------------
		-------------------------------------------------------------------------------------

			If OBJECT_ID ('Tempdb..#UnhashedMIDs') Is Not Null Drop Table #UnhashedMIDs
			Select ro.ID RetailOutletID
				 , [SLC_Report].[dbo].[RetailOutlet].[MerchantID] as MID_GAS_New
			Into #UnhashedMIDs
			From SLC_Report..RetailOutlet ro
			Where [SLC_Report].[dbo].[RetailOutlet].[MerchantID] Not Like '#%'
			And [SLC_Report].[dbo].[RetailOutlet].[MerchantID] Not Like 'x%'
			And [SLC_Report].[dbo].[RetailOutlet].[MerchantID] Not Like 'ARCHIVED-%'
			And Len([SLC_Report].[dbo].[RetailOutlet].[MerchantID]) > 0
			And exists (Select 1
							From Relational.MIDTrackingGAS mtg --Relational.MIDTrackingGAS mtg
							Where ro.ID = mtg.RetailOutletID
							And ro.PartnerID = mtg.PartnerID
							And (mtg.MID_Gas Like '#%' Or
								 mtg.MID_Gas Like 'x%' Or 
								 mtg.MID_Gas Like 'ARCHIVED-%'));		--	And ro.ID = mtg.RetailOutletID added 2018-09-24 RF


		-------------------------------------------------------------------------------------
		----------------  UPDATE MID_GAS with new hashed value and EndDate   ----------------
		-------------------------------------------------------------------------------------

			Insert Into Relational.MIDTrackingGAS ([Relational].[MIDTrackingGAS].[PartnerID]
												 , [Relational].[MIDTrackingGAS].[RetailOutletID]
												 , [Relational].[MIDTrackingGAS].[MID_GAS]
												 , [Relational].[MIDTrackingGAS].[MID_Join]
												 , [Relational].[MIDTrackingGAS].[StartDate]
												 , [Relational].[MIDTrackingGAS].[EndDate])
			Select #UnhashedMIDs.[mtg].PartnerID
				 , #UnhashedMIDs.[mtg].RetailOutletID
				 , [uhm].[MID_GAS_New]
				 , #UnhashedMIDs.[mtg].MID_Join
				 , @MatchDate as StartDate
				 , Null as EndDate
			From Relational.MIDTrackingGAS mtg
			Inner Join #UnhashedMIDs uhm
				on #UnhashedMIDs.[mtg].RetailOutletID=uhm.RetailOutletID
			Where #UnhashedMIDs.[mtg].MID_GAS = #UnhashedMIDs.[mtg].MID_Join;


	--------------------------------------------------------------------------------------------------------------------
	----------------------------------------   Insert any newly inserted MIDs   ----------------------------------------
	--------------------------------------------------------------------------------------------------------------------

		-------------------------------------------------------------------------------------
		------------------------   Retrieve Newly created GAS MIDs   ------------------------
		-------------------------------------------------------------------------------------

			If OBJECT_ID('Tempdb..#NewOutLets') Is Not Null Drop Table #NewOutLets
			Select ro.ID as RetailOutletID
				 , PartnerID
				 , MerchantID as MID_GAS
				 , Convert(Date,RegistrationDate) as StartDate
				 , Case
						When MerchantID Like '#%' Or MerchantID Like 'x%' Then @EndDate
						Else Convert(Date,Null)
				   End as EndDate
			Into #NewOutLets
			From SLC_Report..RetailOutlet ro
			Inner Join SLC_Report..Fan F
				on ro.FanID=f.ID
			Where Len(MerchantID) > 0
			And not exists (Select 1
							From Relational.MIDTrackingGAS mtg
							Where ro.ID = mtg.RetailOutletID);

		-------------------------------------------------------------------------------------
		-------------------------   GAS MID Match to MIDs in BPD   --------------------------
		-------------------------------------------------------------------------------------
		
			If OBJECT_ID('Tempdb..#NewOutLetsWithData') Is Not Null Drop Table #NewOutLetsWithData;
			With
				NewOutletsInCC as (
					Select no.RetailOutletID
						 , no.PartnerID
						 , no.MID_GAS
						 , #NewOutLets.[cc].MID as MID_Join
						 , no.StartDate
						 , [no].[EndDate]
					From #NewOutLets no
					Left Join Relational.ConsumerCombination cc
						on #NewOutLets.[cc].MID=Replace(Replace(no.MID_GAS,'#',''),'x','')),
						
				NewOutletsInCCLeadingZero as (
					Select no.RetailOutletID
						 , no.PartnerID
						 , no.MID_GAS
						 , #NewOutLets.[cc].MID as MID_Join
						 , no.StartDate
						 , [no].[EndDate]
					From #NewOutLets no
					Left Join Relational.ConsumerCombination cc
						on '0'+#NewOutLets.[cc].MID=Replace(Replace(no.MID_GAS,'#',''),'x','')
					Where LEN(#NewOutLets.[cc].MID) = 7),
						
				NewOutletsInMatch as (
					Select no.RetailOutletID
						 , no.PartnerID
						 , no.MID_GAS
						 , ma.MerchantID as MID_Join
						 , no.StartDate
						 , EndDate
					From #NewOutLets no
					Left Join #SLC_Report_Match ma
						on ma.RetailOutletID=no.RetailOutletID
						and ma.MerchantID like '%' + Replace(Replace(no.MID_GAS,'#',''),'x',''))

			Select Distinct
					*
				  , RANK() Over (Partition by RetailOutletID Order by Case when #NewOutLets.[cc] Is Null Then Null else 'Not null' End Desc) as Rank
			Into #NewOutLetsWithData
			From (
				Select * From NewOutletsInCC
				Union
				Select * From NewOutletsInCCLeadingZero
				Union
				Select * From NewOutletsInMatch) no


		Insert into Relational.MIDTrackingGAS ([Relational].[MIDTrackingGAS].[PartnerID]
											 , [Relational].[MIDTrackingGAS].[RetailOutletID]
											 , [Relational].[MIDTrackingGAS].[MID_GAS]
											 , [Relational].[MIDTrackingGAS].[MID_Join]
											 , [Relational].[MIDTrackingGAS].[StartDate]
											 , [Relational].[MIDTrackingGAS].[EndDate])
			Select #NewOutLetsWithData.[PartnerID]
				 , #NewOutLetsWithData.[RetailOutletID]
				 , #NewOutLetsWithData.[MID_GAS]
				 , #NewOutLetsWithData.[MID_Join]
				 , #NewOutLetsWithData.[StartDate]
				 , #NewOutLetsWithData.[EndDate]
			From #NewOutLetsWithData
			Where #NewOutLetsWithData.[Rank] = 1

	----------------------------------------------------------------------------------------------------------------------
	----------------------------------   Update entry in JobLog Temp table with EndDate   --------------------------------
	----------------------------------------------------------------------------------------------------------------------

	--	Update staging.JobLog_Temp
	--	Set EndDate = GETDATE()
	--	Where StoredProcedureName = OBJECT_NAME(@@PROCID)
	--	And TableSchemaName = 'Relational'
	--	And TableName = 'MIDTrackingGAS'
	--	And EndDate is null

	----------------------------------------------------------------------------------------------------------------------
	---------------------------------   Update entry in JobLog Temp table with Row Count   -------------------------------
	----------------------------------------------------------------------------------------------------------------------

	--	Update staging.JobLog_Temp
	--	Set TableRowCount = (Select COUNT(*) from Relational.MIDTrackingGAS)
	--	Where StoredProcedureName = OBJECT_NAME(@@PROCID)
	--	And TableSchemaName = 'Relational'
	--	And TableName = 'MIDTrackingGAS'
	--	And TableRowCount is null

	----------------------------------------------------------------------------------------------------------------------
	-------------------------------------------   Insert entry to JobLog table   -----------------------------------------
	----------------------------------------------------------------------------------------------------------------------
	
	--	Insert into staging.JobLog
	--	Select StoredProcedureName
	--		 , TableSchemaName
	--		 , TableName
	--		 , StartDate
	--		 , EndDate
	--		 , TableRowCount
	--		 , AppendReload
	--	From staging.JobLog_Temp

	--	Truncate Table staging.JobLog_Temp

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
	INSERT INTO Staging.ErrorLog ([Staging].[ErrorLog].[ErrorDate], [Staging].[ErrorLog].[ProcedureName], [Staging].[ErrorLog].[ErrorLine], [Staging].[ErrorLog].[ErrorMessage], [Staging].[ErrorLog].[ErrorNumber], [Staging].[ErrorLog].[ErrorSeverity], [Staging].[ErrorLog].[ErrorState])
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run

END