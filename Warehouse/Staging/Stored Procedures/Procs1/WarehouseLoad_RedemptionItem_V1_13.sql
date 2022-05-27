/*
Author:		Stuart Barnley
Date:		12th March 2013
Purpose:	To Build a Redemption items table in the staging schema
			then Relational schema of the Warehouse database
		
Notes:		Redemption Items contains a distinct list of the different redemptions available (past and 
			Present) to the customer base
Update:		This version is being amended for use as a stored procedure and to be ultimately automated.	
			
			20-02-2014 - SB - Amended to remove warehouse references
			18-03-2015 - SB - New Zinio Redemptions do not confrm to any naming convention
			24-06-2015 - SB - Added link to trade up value table so trade ups identified as expected
			26-11-2015 - SB - Change to allow donations to happen	
			16-12-2015 - SB - Change to allow for PartnerIDs from Trade Up Table
				
*/
CREATE Procedure [Staging].[WarehouseLoad_RedemptionItem_V1_13]
As
Begin

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13',
			TableSchemaName = 'Staging',
			TableName = 'RedemptionItem',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	-------------------------------------------------------------------------------------
	---------------Insert Suggested Redemptions in RedemptionItem Table------------------
	-------------------------------------------------------------------------------------
	/*This section is used to add the new redemptions that have been used by CashBack customers to
	  the redemptions table with the suggested Redemption types. The Type identification will need to 
	  be updated in line with the checking phase
	*/
	--Insert Into Staging.RedemptionItem
	If Object_ID('tempdb..#RedeemItems') Is Not Null Drop Table #RedeemItems
	Select RedeemID as RedeemID
		 , SuggestedRedeemType as RedeemType
		 , PrivateDescription  as PrivateDescription
		 , Cast(Null as int) as PartnerID
		 , Cast(Null as [varchar](100)) as [PartnerName]
		 , Cast(Null as [int]) as [TradeUp_WithValue]
		 , Cast(Null as [smallmoney]) as [TradeUp_ClubcashRequired]
		 , Cast(Null as [smallmoney]) as [TradeUp_Value]
		 , Cast(Null as Bit) as Status
	Into #RedeemItems
	from
	(select     r.ID as RedeemID,
				r.Privatedescription,
				Case
					When r.ID in (7191,7192) then 'Trade Up'
					When r.Privatedescription like '%Donation to%' Then 'Charity'
					When r.Privatedescription like '%Donate%' Then 'Charity'
					When r.Privatedescription like '%gift card % CashbackPlus Rewards%' Then 'Trade Up'
					When r.Privatedescription like '%gift Code %' Then 'Trade Up'
					When r.Privatedescription like '%tickets % CashbackPlus Rewards%' Then 'Trade Up'
					When r.Privatedescription like 'Cash to bank account' Then 'Cash'
					When r.Privatedescription like '%RBS Current Account%' Then 'Cash'
					When r.Privatedescription like '%Pay towards your Cashback Plus Credit Card%' then 'Cash'
					When r.Privatedescription like '%for £_ Rewards%' then 'Trade Up'
					When r.Privatedescription like '%for £__ Rewards%' then 'Trade Up'
					When r.Privatedescription like '%Caff%Nero%' then 'Trade Up'
				End as SuggestedRedeemType
	from  Relational.Customer c
					join slc_report.dbo.Trans t on t.FanID = c.FanID
					join slc_report.dbo.Redeem r on r.id = t.ItemID
					inner join slc_report.dbo.RedeemAction ra on t.ID = ra.transid and ra.Status = 1     
					Left outer join Staging.RedemptionItem as ri on t.itemid = ri.redeemid
	where	t.TypeID=3 and ri.redeemid is null
			--r.id not in (select Redeemid from Staging.RedemptionItem)
	group by r.Privatedescription, r.ID 
	) as Redemptions
	Order by SuggestedRedeemType,RedeemID

	/*--------------------------------------------------------------------------------------------------
	----------------------------------Deal with Problem redemption items--------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update #RedeemItems
	Set RedeemType = 'Trade Up',
		TradeUP_WithValue = 1,
		TradeUp_ClubcashRequired = r.TradeUp_ClubcashRequired,
		TradeUp_Value = r.TradeUp_Value
	from #RedeemItems as ri
	inner join relational.RedemptionItem_TradeUpValue  as r
		on ri.RedeemID = r.RedeemID
	/*--------------------------------------------------------------------------------------------------
	----------------------------------Deal with Problem redemption items--------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update #RedeemItems
	Set PartnerID = a.PartnerID,
		PartnerName = p.PartnerName
	--Select	a.RedeemID,
		--	a.PartnerID ,
		--	p.PartnerName
	From
	(Select Case
				When RedeemType = 'Trade Up' and 
								PrivateDescription like '%digital magazines for %Rewards%' then 1000000
				When RedeemType = 'Trade Up' and 
								replace(replace(PrivateDescription,' ',''),'&','') like '%CurrysPCWorld%' then 4001
				When PrivateDescription like '%Caff_ Nero%' then 4319
				When RedeemType = 'Trade Up' Then P.PartnerID
				Else NULL
			End as PartnerID,
			r.RedeemID
	From #RedeemItems as r
	left Outer join relational.Partner as p
		on	r.PrivateDescription like '%'+p.partnername+'%' and
			r.PrivateDescription not like '%Currys%' and
			r.PrivateDescription not like '%PC World%'
	) as a
	inner join Relational.Partner as p
		on a.PartnerID = p.PartnerID

	Insert into Staging.RedemptionItem
	Select *
	From #RedeemItems as ri
	Where ri.RedeemID not in (Select RedeemID from Staging.RedemptionItem)

	Update Staging.RedemptionItem
	Set		PartnerID = p.PartnerID,
			PartnerName = p.PartnerName
	from Staging.RedemptionItem as ri
	inner join relational.RedemptionItem_TradeUpValue as t
		on	ri.RedeemID = t.RedeemID
	inner join relational.partner as p
		on  t.PartnerID = p.PartnerID
	Where	ri.PartnerID is null and
			t.partnerid is not null


	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13' and
			TableSchemaName = 'Staging' and
			TableName = 'RedemptionItem' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Staging.RedemptionItem) - (Select COUNT(*) from Relational.RedemptionItem)
	where	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13' and
			TableSchemaName = 'Staging' and
			TableName = 'RedemptionItem' and
			TableRowCount is null
		
	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13',
			TableSchemaName = 'Relational',
			TableName = 'RedemptionItem',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'	
	------------------------------------------------------------------------------
	---------------Create Relational.RedemptionItem Table-------------------------
	------------------------------------------------------------------------------

	--if Object_ID('Relational.RedemptionItem') Is Not Null Drop Table Relational.RedemptionItem
	Truncate table Relational.RedemptionItem
	Insert Into Relational.RedemptionItem
	Select RedeemID
		 , RedeemType
		 , PrivateDescription
		 , Status
	From Staging.RedemptionItem

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13' and
			TableSchemaName = 'Relational' and
			TableName = 'RedemptionItem' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.RedemptionItem)
	where	StoredProcedureName = 'WarehouseLoad_RedemptionItem_V1_13' and
			TableSchemaName = 'Relational' and
			TableName = 'RedemptionItem' and
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

	TRUNCATE TABLE staging.JobLog_Temp

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



