/*

	Author:			Stuart Barnley
	
	
	Date:			4th May 2017
	
	
	Purpose:		pull out a list of e-codes that need to be populated to 
					the Redemption table

	Update:			20170810 SB - Update to correct row count problems

*/
CREATE PROCEDURE [Staging].[WarehouseLoad_Redemptions_Ecodes]
AS
BEGIN

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY


	Declare @Date date = Getdate(),
			@Now datetime = GetDate(),
			@RowCount int

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'WarehouseLoad_Redemptions_Ecodes',
			TableSchemaName = 'Relational',
			TableName = 'Redemptions',
			StartDate = @Now,
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'

	-------------------------------------------------------------------------------
	-------------------------Find entries for Issued E-Codes-----------------------
	-------------------------------------------------------------------------------
	IF OBJECT_ID ('tempdb..#eRed_Issues') IS NOT NULL 
													DROP TABLE #eRed_Issues
	Select	e.ECodeID,
			StatusChangeDate as IssuedDate
	Into #eRed_Issues
	from SLC_Report.Redemption.ECodeStatusHistory as e
	Left Outer join [Staging].[Redemptions_ECodes] as a
		on e.ecodeid = a.ecodeid
	Where	e.Status = 1 and
			e.StatusChangeDate <= @Date and
			a.ECodeID is null

	Create Clustered index cix_eRed_Issues_ECodeID on #eRed_Issues (ECodeID)

	-------------------------------------------------------------------------------
	----------------------Find some details to fill out records--------------------
	-------------------------------------------------------------------------------
	IF OBJECT_ID ('tempdb..#RedsData') IS NOT NULL 
											DROP TABLE #RedsData
	Select	t.FanID,
			e.TransID as TranID,
			r.IssuedDate as RedeemDate,
			t.ClubCash as CashbackUsed,
			0 as Cancelled,
			ItemID,
			r.ECodeID
	Into	#RedsData
	From #eRed_Issues as r
	inner join SLC_report.Redemption.ECode as e
		on r.ECodeID = e.ID
	inner join SLC_report.dbo.trans as t
		on e.TransID = t.id
	
	Create Clustered index cix_RedsData_RedeemID on #RedsData (ItemID)

	-------------------------------------------------------------------------------
	------------------Finish filling in details to populate records----------------
	-------------------------------------------------------------------------------

	Insert into [Staging].[Redemptions_ECodes] 
	Select  rd.FanID,
			c.CompositeID,
			rd.TranID,
			rd.RedeemDate,
			r.RedeemType,
			r.PrivateDescription as RedemptionDescription,
			ri.PartnerID,
			p.PartnerName,
			rd.CashbackUsed,
			1 as [TradeUp_WithValue],
			ri.TradeUp_Value,
			0 as Cancelled,
			rd.ECodeID
	from #RedsData as rd
	Left Outer join Relational.RedemptionItem_TradeUpValue as ri
		on rd.ItemID = ri.RedeemID
	inner join Relational.RedemptionItem as r
		on rd.ItemID = r.RedeemID
	inner join relational.customer as c
		on rd.FanID = c.FanID
	inner join relational.Partner as p
		on ri.partnerid = p.PartnerID
	Left Outer join [Staging].[Redemptions_ECodes] as e
		on rd.TranID = e.TranID
	Where e.TranID is null
	Order by c.CompositeID

	-------------------------------------------------------------------------------
	----------------Find those subsequently cancelled in some form-----------------
	-------------------------------------------------------------------------------

	Update a
	Set		Cancelled = 1
	From [Staging].[Redemptions_ECodes] as a 	
	inner join SLC_Report.Redemption.ECodeStatusHistory as e
		on	a.ECodeID = e.ECodeID and
			e.Status >= 1 and
			e.StatusChangeDate > a.RedeemDate and
			a.Cancelled = 0

	-------------------------------------------------------------------------------
	------------------------Insert final records into table------------------------
	-------------------------------------------------------------------------------
	Insert into [Relational].[Redemptions]
	Select	e.FanID,
			e.CompositeID,
			e.TranID,
			e.RedeemDate,
			e.RedeemType,
			e.RedemptionDescription,
			e.PartnerID,
			e.PartnerName,
			e.CashbackUsed,
			e.TradeUp_WithValue,
			e.TradeUp_Value,
			e.Cancelled,
			CAST(0 AS BIT) AS GiftAid
	From [Staging].[Redemptions_ECodes] as e
	left Outer join Relational.Redemptions as r
		on e.tranid = r.tranid
	Where r.tranid is null
	Set @RowCount = @@RowCount

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	Set @Now = GetDate()

	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		EndDate = @Now,
			TableRowCount = @RowCount
	where	StoredProcedureName = 'WarehouseLoad_Redemptions_Ecodes' and
			TableSchemaName = 'Relational' and
			TableName = 'Redemptions' and
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

End