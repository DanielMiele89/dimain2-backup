/*

	Date:		19th May 2017

	Author:		Stuart Barnley

	Purpose:	To provide some stats to Marketing regarding Redemptions used and Stock levels.

	
*/

CREATE PROCEDURE [WHB].[Redemptions_SSRS_R0164_ERA_Redemption_Stats_Populate]
--With Execute As Owner
As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/
	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Staging',
			TableName = 'R_0155_ERA_Redemptions_Report',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'A'
	-------------------------------------------------------------------------------------------------------
	---------------------------Calculate latest reporting week and update table in needed------------------
	-------------------------------------------------------------------------------------------------------
	Declare @EndDateTime Datetime ,
			@StartDateTime Datetime 
	Set @EndDateTime = (Select Max(EndDate) From Staging.R_0155_ERedemptions_Dates)
	Set @StartDateTime = (Select Max(StartDate) From Staging.R_0155_ERedemptions_Dates)

	Declare @EndDate Date = (Select Cast(@EndDateTime as Date)),
			@LastSunday date

	--Select @EndDate,@EndDateTime,@StartDateTime

	set datefirst 1
	Set @LastSunday = (Select Dateadd(day,-DATEPART(dw,GetDate()),getdate())
	)

	--Select @LastSunday

	--**********Add entries for every missign week

	While @LastSunday > @EndDateTime
	Begin
		Insert into Staging.R_0155_ERedemptions_Dates
		Select Dateadd(day,7,@StartDateTime) as StartDateTime,
			   Dateadd(day,7,@EndDateTime) as EndDateTime
	
		Set @EndDateTime = (Select Max(EndDate) From Staging.R_0155_ERedemptions_Dates)
		Set @StartDateTime = (Select Max(StartDate) From Staging.R_0155_ERedemptions_Dates)
	End



	-------------------------------------------------------------------------------------------------------
	-----------------------------Find a list of RedeemIDs that need to be reported on----------------------
	-------------------------------------------------------------------------------------------------------

	if object_id('tempdb..#RedeemItems') is not null drop table #RedeemItems 
	Select	r.ID as RedeemID,
			r.[Description],
			t.PartnerID,
			p.PartnerName,
			r.[Status],
			r.ValidityDays,
			r.WarningStockThreshold
	Into #RedeemItems
	From SLC_report.dbo.Redeem as r
	Left Outer join Staging.R_0155_ERedemptions_RedeemIDExclusions as a
		on r.id = a.redeemid
	inner join relational.RedemptionItem_TradeUpValue as t
		on r.id = t.RedeemID
	inner join relational.partner as p
		on t.PartnerID = p.PartnerID
	Where	IsElectronic = 1 and
			a.RedeemID is null

	Create Clustered Index cix_RedeemItems_RedeemID on #RedeemItems (RedeemID)

	-------------------------------------------------------------------------------------------------------
	--------------------------------------------Get sales figures per week---------------------------------
	-------------------------------------------------------------------------------------------------------
	if object_id('tempdb..#Stats') is not null drop table #Stats 
	Select	StartDate,
			EndDate,
			Count(*) as Redemptions,
			Min(RedeemDate) as FirstTrans,
			Max(RedeemDate) as LastTrans,
			RedeemID,
			a.RowNumber
	Into #Stats
	From Relational.Redemptions as r
	inner join slc_report.dbo.trans as t with (nolock)
		on r.TranID = t.id
	inner join #RedeemItems as ri
		on t.ItemID = ri.RedeemID
	inner join	(Select *, ROW_NUMBER() OVER (ORDER BY EndDate Desc) AS RowNumber
				from Staging.R_0155_ERedemptions_Dates as a) as a
		on r.RedeemDate Between a.StartDate and a.EndDate
	Where Cancelled = 0
	Group by StartDate,ENdDate,RedeemID,a.RowNumber

	Create Clustered Index cix_Stats_RedeemID on #Stats (RedeemID)

	-------------------------------------------------------------------------------------------------------
	-------------------------------------------------YTD Figures-------------------------------------------
	-------------------------------------------------------------------------------------------------------

	Declare @YTD Int = Year(@EndDate)

	if object_id('tempdb..#StatsYTD') is not null drop table #StatsYTD
	Select	RedeemID,
			Count(*) as YTDRedemptions
	Into #StatsYTD
	From Relational.Redemptions as r
	inner join slc_report.dbo.trans as t with (nolock)
		on r.TranID = t.id
	inner join #RedeemItems as ri
		on t.ItemID = ri.RedeemID
	Where Cancelled = 0 and
			Year(r.RedeemDate) = @YTD
	Group By RedeemID

	Create Clustered Index cix_StatsYTD_RedeemID on #StatsYTD (RedeemID)


	-------------------------------------------------------------------------------------------------------
	----------------------------------Get Start and EndDate of 4 week period-------------------------------
	-------------------------------------------------------------------------------------------------------

	if object_id('tempdb..#FirstLast') is not null drop table #FirstLast 

	Select Min(StartDate) as SDate, Max(EndDate) as EDate
	Into #FirstLast
	From
	(
	Select top 4 StartDate,EndDate
	From Staging.R_0155_ERedemptions_Dates
	Order by StartDate Desc
	) as a

	DECLARE @SDate Datetime =  (Select SDate From #FirstLast)
	Declare @EDate Datetime =  (Select EDate From #FirstLast)

	-------------------------------------------------------------------------------------------------------
	----------------------------------Find those redemptions run for less----------------------------------
	-------------------------------------------------------------------------------------------------------

	if object_id('tempdb..#Shorter') is not null drop table #Shorter 

	Select	RedeemID,
			Sum(Datediff(day,StartDate,EndDate)+1) as [Days]
	Into #Shorter
	From (
	Select	RedeemID,
			Case
				When StartDate is null then @SDate
				Else Startdate
			End as StartDate,
			Case
				When EndDate is null then @EDate
				Else DateAdd(ss,-1,Dateadd(day,1,Cast(EndDate as Datetime)))
			End 	as EndDate
	From Relational.RedemptionItem_Dates as a
	Where	StartDate Between @SDate and @EDate or
			EndDate Between @SDate and @EDate
	) as a
	Group By RedeemID

	Create Clustered index cix_Shorter_RedeemID on #Shorter (RedeemID)

	-------------------------------------------------------------------------------------------------------
	-----------------------------Calculate Averages per week for redemptions-------------------------------
	-------------------------------------------------------------------------------------------------------
	if object_id('tempdb..#Averages') is not null drop table #Averages 
	Select s.RedeemID,[Days],
			Case
				When a.Days is null then ROUND(Sum(cAST(Redemptions AS REAL))/4,0) 
				Else ROUND(Sum(cAST(Redemptions AS REAL))/(Cast([Days] as Real)/7),0) 
			End as [Average]
	Into #Averages
	From #Stats as s
	Left Outer Join #Shorter as a
		on s.RedeemID = a.RedeemID
	Where RowNumber <= 4
	Group by s.RedeemID,[Days]

	Create Clustered index cix_Averages_RedeemID on #Averages (RedeemID)

	-------------------------------------------------------------------------------------------------------
	----------------------Pull through Stock Levels for each Active RedeemItem-----------------------------
	-------------------------------------------------------------------------------------------------------

	if object_id('tempdb..#Stock') is not null drop table #Stock 

	Select RedeemID,Count(*) as Stock
	Into #Stock
	From slc_report.[Redemption].[ECode]
	Where	TransID is null or 
			(Status = 1 and StatusChangeDate >= @EDate)
	Group by RedeemID

	Create Clustered index cix_Stock_RedeemID on #Stock (RedeemID)

	-------------------------------------------------------------------------------------------------------
	-----------------------------------------Delete Duplicate Reporting Rows-------------------------------
	-------------------------------------------------------------------------------------------------------

	Delete from Staging.R_0155_ERA_Redemptions_Report 
	Where ReportDate = @EDate

	-------------------------------------------------------------------------------------------------------
	-----------------------------------------Produce final dataset-----------------------------------------
	-------------------------------------------------------------------------------------------------------

	Declare @RowCount int

	Insert Into Staging.R_0155_ERA_Redemptions_Report
	Select	@EDate as ReportDate,
			RI.RedeemID,
			Cast(RI.[Description] as nvarchar(100)) as Red_Description,
			RI.PartnerID,
			Cast(RI.PartnerName as Varchar(100)) as PartnerName,
			RI.WarningStockThreshold,
			Cast(s.StartDate as DateTime) as StartDate,
			Cast(s.EndDate as DateTime) as EndDate,
			Cast(s.Redemptions as int) as Redemptions,
			s.RowNumber,
			Cast(a.Average as real) as Average,
			Cast(sto.Stock as Int) Stock,
			Cast(y.YTDRedemptions as int) YTD
	from #RedeemItems as RI
	inner join #Stats as s
		on RI.RedeemID = s.RedeemID
	inner join #Averages as a
		on s.RedeemID = a.RedeemID
	Left Outer join #Stock as sto
		on ri.RedeemID = sto.RedeemID
	left outer join #StatsYTD as y
		on ri.RedeemID = y.RedeemID
	Order by s.RedeemID,RowNumber
	Set @RowCount = @@ROWCOUNT

	/*--------------------------------------------------------------------------------------------------
	-------------------------Update entry in JobLog Table with End Date and RowCount--------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE(),
			TableRowCount = @RowCount
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Staging' and
			TableName = 'R_0155_ERA_Redemptions_Report' and
			EndDate is null

	/*--------------------------------------------------------------------------------------------------
	-------------------------Update entry in JobLog Table with End Date and RowCount--------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog
	select	[StoredProcedureName],
			[TableSchemaName],
			[TableName],
			[StartDate],
			[EndDate],
			[TableRowCount],
			[AppendReload]
	from staging.JobLog_Temp

	TRUNCATE TABLE staging.JobLog_Temp

	--Select * from Warehouse.Staging.R_0155_ERA_Redemptions_Report

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