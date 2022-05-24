/*

	Author:		Stuart Barnley

	Date:		21th July 2017

	Purpose:	Populate Customer Random number table, this is used by OPE process to 
				deal with conflicts

*/

CREATE PROCEDURE [Selections].[Populate_OPE_Customer_Numbers]
AS
BEGIN

	DECLARE @RowNo INT

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog_Temp Table---------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Truncate Table staging.JobLog_Temp

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = 'Populate_OPE_Customer_Numbers',
			TableSchemaName = 'Selections',
			TableName = 'OPECustomer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	/*--------------------------------------------------------------------------------------------------
	------------------------------Empty Table in Preparation for new data-------------------------------
	----------------------------------------------------------------------------------------------------*/

	--Truncate table Selections.OPECustomer

	--/*--------------------------------------------------------------------------------------------------
	-----------------------------Add entries for all active customers in RBSG-----------------------------
	------------------------------------------------------------------------------------------------------*/

	--INSERT INTO Selections.OPECustomer 
	--SELECT fanid, 
	--	   rowno % 2 AS Random1, 
	--	   rowno % 3 AS Random2, 
	--	   rowno % 4 AS Random3 
	--FROM  (SELECT fanid, 
	--			  Row_number() 
	--				OVER( 
	--				  ORDER BY Newid() DESC) AS RowNo 
	--	   FROM   warehouse.relational.customer 
	--	   WHERE  currentlyactive = 1) AS a 
	--Set @RowNo = @@ROWCOUNT
	
	/*--------------------------------------------------------------------------------------------------
	------------------------------Empty Table in Preparation for new data-------------------------------
	----------------------------------------------------------------------------------------------------*/

		TRUNCATE TABLE [Selections].[OPE_Customer]
	
		ALTER INDEX IX_CompIDRandNo ON [Selections].[OPE_Customer] DISABLE

		INSERT INTO [Selections].[OPE_Customer] (FanID
											   , CompositeID
											   , RandomNumber)
		SELECT FanID
			 , CompositeID
			 , ABS(CHECKSUM(NEWID())) AS RandomNumber
		FROM [Relational].[Customer]

		ALTER INDEX IX_CompIDRandNo ON [Selections].[OPE_Customer] REBUILD

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Declare @Date datetime = Getdate()

	Update  staging.JobLog_Temp
	Set		EndDate = @Date,
			TableRowCount = @RowNo
	where	StoredProcedureName = 'Populate_OPE_Customer_Numbers' and
			TableSchemaName = 'Selections' and
			TableName = 'OPECustomer' and
			EndDate is null

	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/

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

END