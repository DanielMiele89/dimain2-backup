
/*
Author:		Stuart Barnley
Date:		23rd September 2013
Purpose:	To Build the Customer table first in the Staging and then Relational schema of the Warehouse database

Notes:		Amended to remove LaunchedTo and Control group customers who are no longer needed in this table.
			19-02-2014 SB - Sort out indexes on Customer table to speed up population time (unused indexes removed).
			17-04-2014 SC - added 19587579 to exclusion list - this is a fake record
			29-04-2014 SB - Amended to find all customers who ever activated, some tidying done at the same time
			20-08-2014 SC - Removed Account Key from Staging.Customer
			09-09-2014 SC - Added Primary Key and altered all indexing
			30-09-2014 SB - Remove from Staging.Customers those customers in the Staging.Customer_TobeExcluded table.

CJM 20161116 see ln215
*/
CREATE Procedure [Staging].[WarehouseLoad_Customer_V1_20]
as
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	Declare @LaunchDate Date = 'Aug 08, 2013'

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_V1_20',
			TableSchemaName = 'Staging',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers who's AgreedTCs was removed-------------------------
	----------------------------------------------------------------------------------------------------*/

	If Object_ID('tempdb..#PrevAct') Is Not Null Drop Table #PrevAct
	Select FanID
		 , [Date] as AgreedTCs
	Into #PrevAct
	From Staging.InsightArchiveData as iad
	Where iad.TypeID = 1 
	
	Create Clustered Index CIX_PrevAct_Fan on #PrevAct (FanID)

	/*--------------------------------------------------------------------------------------------------
	----------------------Create Table of Customers unsubscribes & hard bounces-------------------------
	----------------------------------------------------------------------------------------------------*/
	
	If Object_ID('tempdb..#EmailEvent') Is Not Null Drop Table #EmailEvent
	Select FanID
		 , Unsubscribe
		 , HardBounce
	Into #EmailEvent
	From (Select ee.FanID
				, Max(Case When EmailEventCodeID = 301 Then [Date] Else NULL End) as UnSubscribe
				, Max(Case When EmailEventCodeID = 702 Then [Date] Else NULL End) as HardBounce
		  From SLC_Report.dbo.EmailEvent as ee
		  Where EmailEventCodeID In (301, 702) -- CJM 20161116 uncomment this
		  Group by FanID) as ee
	Where Unsubscribe Is Not Null
	Or Hardbounce Is Not Null
	
	Create Clustered Index CIX_EmailEvent_Fan on #EmailEvent (FanID)

	/*--------------------------------------------------------------------------------------------------
	-----------------------------------Create CustomerAttribute Table-----------------------------------
	----------------------------------------------------------------------------------------------------*/
	
	If Object_ID('tempdb..#CustomerAttribute') Is Not Null Drop Table #CustomerAttribute
	Select Distinct FanID
	Into #CustomerAttribute
	from Relational.CustomerAttribute as ca
	Inner join Relational.CinList as CL
		on ca.CinID = CL.CinID
	Inner join Relational.Customer as c
		on cl.CIN = c.SourceUID
	Where BankID > 2
	
	Create Clustered Index CIX_CustomerAttribute_Fan on #CustomerAttribute (FanID)
	
	------------------------------------------------------------------------
	-------------Insert Main Data in Staging.Customer Table-----------------
	------------------------------------------------------------------------

	Truncate Table Staging.Customer
	Insert Into Staging.Customer
	Select f.ID as FanID
		 , Case
				When f.AgreedTCs = 0 Then 0
				When f.AgreedTCsDate Is Null Then 0
				Else f.Status
			End  as [Status]
		 , Convert(VarChar(20), f.SourceUID) as SourceUID   --this links to CIN in the data from RBS
		 , f.DOB as DOB
		 , Convert(VarChar(20), f.Title) as Title
		 , Convert(VarChar(50), f.FirstName) as FirstName
		 , Convert(VarChar(50), f.LastName) as LastName
		 , Convert(VarChar(100), f.Address1) as Address1
		 , Convert(VarChar(100), f.Address2) as Address2
		 , Convert(VarChar(100), f.City) as City
		 , Convert(VarChar(100), f.County) as County
		 , IsNull(LTrim(RTrim(Convert(VarChar(10), f.Postcode))), '') as PostCode
		 , Convert(VarChar(100), f.Email) as Email
		 , Convert(Date, Coalesce(pa.AgreedTCs,f.AgreedTCsDate)) as AgreedTCsDate		--Date Activated
		 , Convert(Bit, coalesce(OfflineOnly,0)) as OfflineOnly			--Activated at contact centre
		 , Convert(Bit, ContactByPost) as ContactByPost		--This is set by a tick box within the CBP Site. It is ticked by default, indicating agreement to receive direct mail
			--***************************************************************************
			--*******************Start To be reviewed at later point*********************
			--***************************************************************************
		 , Case
				When Convert(Bit, f.Unsubscribed) = 1 Then 1
				When UnSub.Unsubscribe Is Null Then 0
				When UnSub.Unsubscribe > f.AgreedTCsDate Then 1
				When UnSub.Unsubscribe Is Not Null And f.AgreedTCsDate < @LaunchDate Then 1
				Else 0
		   End as Unsubscribed
		 , Case
				When cast(f.HardBounced as bit) = 1 Then 1
				When UnSub.HardBounce Is Null Then 0
				When UnSub.HardBounce < @LaunchDate and AgreedTCsDate < @LaunchDate Then 1 --Legacy to not contact those we were ignoring
				When UnSub.HardBounce > f.AgreedTCsDate Then 1
				Else 0 
		   End as Hardbounced
			--***************************************************************************
			--********************End To be reviewed at later point**********************
			--***************************************************************************
		 , Convert(BigInt, f.CompositeID) as CompositeID
		 , Convert(Char(1), a.Primacy) as Primacy
		 , Convert(Bit, a.IsJoint) as IsJoint
		 , Convert(TinyInt, a.ControlGroupNumber) as ControlGroupNumber
		 , Convert(TinyInt, a.ReportGroup) as ReportGroup
		 , Convert(TinyInt, a.TreatmentGroup) as TreatmentGroup
		 , Convert(Char(4), a.LaunchGroup) as LaunchGroup
		 , Convert(Bit, a.OriginalEmailPermission) as OriginalEmailPermission
		 , Convert(Bit, a.OriginalDMPermission) as OriginalDMPermission
		 , Convert(Bit, a.EmailOriginallySupplied) as EmailOriginallySupplied
		 , Convert(TinyInt, Case	
								When f.DOB > Convert(Date, GetDate()) Then 0
								When month(f.DOB) > month(GetDate()) Then DateDiff(yyyy, f.DOB, GetDate()) - 1 
								When month(f.DOB) < month(GetDate()) Then DateDiff(yyyy, f.DOB, GetDate()) 
								When month(f.DOB) = month(GetDate()) Then Case
																		  	  When day(f.DOB) > day(GetDate()) Then DateDiff(yyyy, f.DOB,GetDate()) - 1 
																		  	  Else DateDiff(yyyy,f.DOB,GetDate()) 
																		  End 
							 End) as AgeCurrent
		 , Convert(TinyInt, Null) as AgeAtLaunch
		 , Convert(TinyInt, Null) as AgeCurrentBandNumber
		 , Convert(Char(1), Case
								When f.Sex = 1 Then 'M'
								When f.Sex = 2 Then 'F'
								Else 'U'
							End) as Gender
		 , Convert(VarChar(6), Null) as PostalSector
		 , Convert(VarChar(4), Case 
									When f.Postcode Is Null Then ''
									When CharIndex(' ', f.PostCode) = 0 Then Convert(VarChar(4), f.PostCode) 
									Else Left(f.PostCode, CharIndex(' ', f.PostCode) - 1) 
							   End) as PostCodeDistrict
		 , Convert(VarChar(2), Case 
									When f.Postcode Is Null Then ''
									When f.PostCode Like '[A-Z][0-9]%' Then Left(f.PostCode, 1) 
									Else Left(f.PostCode, 2) 
							   End) as PostArea
		 , Convert(VarChar(30), Null) as Region
		 , Convert(Bit, Case 
							When f.Email Like '%@%.%' and f.Email Not Like '%@%.'			
							 And f.Email Not Like '@%.%' and f.Email Not Like '@.%'		
							 And f.Email Not Like '%@%@%' and f.Email Not Like '%[:-?]%' 
							 And f.Email Not Like '%,%' and LTrim(RTrim(f.Email)) Not Like '% %' 
							 And Len(LTrim(RTrim(f.Email))) >= 9 Then 1 
							Else 0 
						End) as EmailStructureValid
		 , Case --	Used to make sure we do not start including people previously excluded in POC
				When a.IsControl = 1 and AgreedTCsDate < @LaunchDate Then 0 ---**************** to be resolved
				When f.Status = 0 Then 0
				When f.AgreedTCs = 0 Then 0
				When Len(f.Postcode) < 3 Then 0
				Else Convert(Bit, Null)					
			End as MarketableByEmail
		 , Convert(Bit, Null) as MarketableByDirectMail
		 , Convert(Bit, Null) as EmailNonOpener
		 , f.MobileTelephone as MobileTelephone
		 , Convert(Bit, Case
							When (Left(Replace(f.MobileTelephone, ' ', ''), 2) Like '07' Or Left(Replace(f.MobileTelephone,' ',''),4) Like '+447')
								And Len(Replace(f.MobileTelephone, ' ', '')) >= 11 Then 1
							Else 0
						End) as ValidMobile
		 , Convert(VarChar(100), Case
									When Len(Replace(f.Title, ' ', '')) > 1 Then 'Dear ' + f.Title + ' ' + f.LastName
									When (Len(Replace(f.Title, ' ', '')) <= 1 Or f.Title Is Null) And f.Sex = 1 Then 'Dear Mr ' + f.LastName
									Else Null
								 End) as Salutation
		 , Convert(Bit, a.CurrentEmailPermission) as CurrentEmailPermission
		 , Convert(Bit, a.CurrentDMPermission) as CurrentDMPermission
		 , f.ClubID
		 , Case
				When f.Status = 0 or f.AgreedTCs = 0 or f.AgreedTCsDate Is Null Then ca.DeactivatedDate
				Else Null
			End as DeactivatedDate
		 , Case
				When f.Status = 0 or f.AgreedTCs = 0 or f.AgreedTCsDate Is Null Then ca.OptedOutDate
				Else Null
			End as OptedOutDate
		 , Convert(Bit, Null) as CurrentlyActive
		 , Case
				when cb.FanID Is Null Then 0
				When cb.Activated = 1 Then 1
				Else 0
		   End as POC_Customer
		 , Case
				When Rainbow.FanID Is Null Then 0
				Else 1
		   End as Rainbow_Customer
	From SLC_Report.dbo.Fan f
	Left join Archive_Light.Prod.NobleFanAttributes a 
		on f.CompositeID = a.CompositeID
	Left join #PrevAct as pa
		on f.ID = pa.FanID
	Left join MI.CustomerActiveStatus ca
		on f.ID = ca.FanID
	Left join [InsightArchive].[Customer_Backup20130724] as cb
		on f.ID = cb.FanID
	Left join #EmailEvent as UnSub
		on f.ID  = UnSub.FanID
	Left join #CustomerAttribute as Rainbow
		on f.ID = Rainbow.FanID
	Where f.ClubID In (132,138)
	And (f.AgreedTCs = 1 or Not(pa.AgreedTCs Is Null))
	And f.ID Not In (19587579)

	------------------------------------------------------------------------
	-----------------------Enchance Customer Data Part 1--------------------
	------------------------------------------------------------------------

	Update cu
	Set PostalSector = Case
							When Replace(Replace(PostCode, Char(160),''),' ','') Like '[a-z][0-9][0-9][a-z][a-z]'
								Then Left(Replace(Replace(PostCode, Char(160),''),' ',''),2) + ' ' + Right(Left(Replace(Replace(PostCode, Char(160), ''), ' ', ''), 3), 1)
							When Replace(Replace(PostCode, Char(160),''),' ','') Like '[a-z][0-9][0-9][0-9][a-z][a-z]'
							  Or Replace(Replace(PostCode, Char(160),''),' ','') Like '[a-z][a-z][0-9][0-9][a-z][a-z]'
							  Or Replace(Replace(PostCode, Char(160),''),' ','') Like '[a-z][0-9][a-z][0-9][a-z][a-z]'
								Then Left(Replace(Replace(PostCode, Char(160), ''), ' ', ''), 3) + ' ' + Right(Left(Replace(Replace(PostCode, Char(160), ''), ' ', ''), 4), 1)
							When Replace(Replace(PostCode, Char(160), ''), ' ', '') Like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]'
							  Or Replace(Replace(PostCode, Char(160), ''), ' ', '') Like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'
								Then Left(Replace(Replace(PostCode, Char(160), ''), ' ', ''), 4) + ' ' + Right(Left(Replace(Replace(PostCode, Char(160), ''), ' ', ''), 5), 1)
							Else ''
					   End
	  , cu.Region = pa.Region
	  , EmailNonOpener = Case 
							When eno.FanID Is Null Then 0 
							Else 1 
						  End
	  , AgeCurrentBandNumber = Case 
									When AgeCurrent Is Null then 0
									When Not AgeCurrent Between 18 and 110 then 0
									When AgeCurrent Between 18 and 24 then 1
									When AgeCurrent Between 25 and 34 then 2
									When AgeCurrent Between 35 and 44 then 3
									When AgeCurrent Between 45 and 54 then 4
									When AgeCurrent Between 55 and 64 then 5
									When AgeCurrent Between 65 and 80 then 6
									When AgeCurrent Between 81 and 110 then 7
							   End
	From Staging.Customer cu
	Left Join Staging.PostArea pa
			on (Case When cu.PostCode Like '[A-Z][0-9]%' Then Left(PostCode, 1) Else Left(cu.PostCode, 2) End) = pa.PostAreaCode
	Left join Staging.EmailNonOpener eno
			on cu.FanID = eno.FanID

	------------------------------------------------------------------------
	-----------------------Enchance Customer Data Part 3--------------------
	------------------------------------------------------------------------
	Update Staging.Customer
	Set AgeCurrentBandText = Case 
								When AgeCurrentBandNumber = 0 Then 'Unknown'
								When AgeCurrentBandNumber = 1 Then '18 to 24' 
								When AgeCurrentBandNumber = 2 Then '25 to 34' 
								When AgeCurrentBandNumber = 3 Then '35 to 44' 
								When AgeCurrentBandNumber = 4 Then '45 to 54' 
								When AgeCurrentBandNumber = 5 Then '55 to 64' 
								When AgeCurrentBandNumber = 6 Then '65 to 80' 
								When AgeCurrentBandNumber = 7 Then '81+' 
							 End
	  , MarketableByEmail = Case 
								When AgreedTCsDate Is Not Null
									 And ((LaunchGroup Is Not Null) Or AgreedTCsDate >= 'Aug 08, 2013')	--	not control
									 And Status > 0						--account is active. This field will be set to 0 is customer is deceased. Discussed with Tracy 9 March 2012
									 And Unsubscribed = 0				--customer has not unsubscribed. Joe + Niru to start updating this field from SFD (discussed 15 March 2012)
									 And Hardbounced = 0				--email address has not hardbounced.
									 And EmailStructureValid = 1		--result of basic structutral validation above
									 And OfflineOnly = 0				--customer has not activated offline at contact centre
									 And MarketableByEmail Is Null
								Then 1
								Else 0 
							End
	 , MarketableByDirectMail = Case 
									When LaunchGroup Is Not Null			--as above
										 And Not LaunchGroup = 'INIT'		--etc
										 And Status > 0						--etc
										 And ContactByPost = 1				--This is set by a tick box within the CBP Site. It is ticked by default, indicating agreement to receive direct mail
										 And (EmailStructureValid = 0 or HardBounced = 1)  --In the DM cells or activated but have undeliverable email address					 
										 And Not (EmailStructureValid = 1 and Hardbounced = 0 and Unsubscribed = 0)
								  --	 And IsControl = 0					--etc
									Then 1
									Else 0 
							    End
	 , CurrentlyActive = Case
							When DeactivatedDate Is Null
								 And OptedOutDate Is Null
								 And Status = 1
								 And AgreedTCsDate <= Convert(Date, GetDate())
							Then 1
							Else 0
						 End

	/*--------------------------------------------------------------------------------------------------
	---------------------------------Delete Customer who need excluding---------------------------------
	----------------------------------------------------------------------------------------------------*/
	Delete from Staging.Customer
	From Staging.Customer as c
	Inner join Staging.Customer_TobeExcluded ctbe
		on c.FanID = ctbe.FanID

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_V1_20' and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.Customer)
	where	StoredProcedureName = 'WarehouseLoad_Customer_V1_20' and
			TableSchemaName = 'Staging' and
			TableName = 'Customer' and
			TableRowCount is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Call Store Procedure to look for Deactivation Dates----------------------
	----------------------------------------------------------------------------------------------------*/

	Exec Staging.WarehouseLoad_CustomerDeactivations_V1_2
	
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Customer_V1_20',
			TableSchemaName = 'Relational',
			TableName = 'Customer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'
		
	------------------------------------------------------------------------
	--------------------Create Relational.Customer Table--------------------
	------------------------------------------------------------------------			
	ALTER INDEX i_SourceUID ON Relational.Customer DISABLE
	ALTER INDEX i_CompositeID ON Relational.Customer DISABLE
	ALTER INDEX i_PostArea ON Relational.Customer DISABLE

	Truncate Table Relational.Customer
	Insert Into Relational.Customer
	Select FanID
		 , SourceUID
		 , CompositeID
		 , [Status]
		 , Gender
		 , Title
		 , FirstName
		 , LastName
		 , Salutation
		 , Address1
		 , Address2
		 , City
		 , County
		 , PostCode
		 , PostalSector
		 , PostCodeDistrict
		 , PostArea
		 , Region
		 , Email
		 , Unsubscribed
		 , Hardbounced
		 , EmailStructureValid
		 , MobileTelephone
		 , ValidMobile
		 , Primacy
		 , IsJoint
		 , ControlGroupNumber
		 , ReportGroup
		 , TreatmentGroup
		 , LaunchGroup
		 , 1/*AgreedTCs*/ as Activated
		 , AgreedTCsDate as ActivatedDate
		 , OfflineOnly as ActivatedOffline
		 , MarketableByEmail
		 , MarketableByDirectMail
		 , EmailNonOpener
		 , OriginalEmailPermission --These fields removed (15 March 2012) as potentially confusing and not needed
		 , OriginalDMPermission	 --Added back in 22 March 2012
		 , EmailOriginallySupplied
		 , CurrentEmailPermission
		 , CurrentDMPermission			
		 , DOB
		 , AgeCurrent
		 , AgeCurrentBandNumber
		 , AgeCurrentBandText
		 , ClubID
		 , DeactivatedDate
		 , OptedOutDate
		 , CurrentlyActive
		 , POC_Customer
		 , Rainbow_Customer
		 , 0 as Registered
	From Staging.Customer
		
	ALTER INDEX i_SourceUID ON Relational.Customer REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX i_CompositeID ON Relational.Customer REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212
	ALTER INDEX i_PostArea ON Relational.Customer REBUILD WITH (SORT_IN_TEMPDB = ON) -- CJM 20190212


	/*****************************
	--Change for David Crawford
	*****************************/
	Update Relational.Customer
	Set Hardbounced = 0
	  , MarketableByEmail = 1
	Where FanID = 6137809

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_Customer_V1_20' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.Customer)
	where	StoredProcedureName = 'WarehouseLoad_Customer_V1_20' and
			TableSchemaName = 'Relational' and
			TableName = 'Customer' and
			TableRowCount is null

	Insert into staging.JobLog
	select [StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
	from staging.JobLog_Temp
	Truncate Table Staging.JobLog_Temp

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

END