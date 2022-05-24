/*
		Author:			Stuart Barnley
		Date:			09th March 2015

		Purpose:		Update exclusion list for partner specific offers for certain customers
*/
CREATE Procedure [Staging].[WarehouseLoad_CustomerPartner_Exclusions]
as

TRUNCATE TABLE staging.JobLog_Temp
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'WarehouseLoad_CustomerPartner_Exclusions',
	TableSchemaName = 'Staging',
	TableName = 'CustomerPartner_Exclusions',
	StartDate = GETDATE(),
	EndDate = null,
	TableRowCount  = null,
	AppendReload = 'R'
/*
-------------------------------------------------------------------------------------------------------
-----------------------------Create Table of CustomerPartner Exclusions--------------------------------
-------------------------------------------------------------------------------------------------------
Create Table [Staging].[CustomerPartner_Exclusions] (
		ID int identity (1,1),
		FanID int,
		PartnerID int,
		StartDate Date,
		EndDate date,
		Primary Key (ID)
		)

Create NonClustered Index idx_CustomerPartner_Exclusions_all 
					on [Staging].[CustomerPartner_Exclusions] (FanID,PartnerID,StartDate,EndDate)
*/
-------------------------------------------------------------------------------------------------------
-------------------------Truncate table [Staging].[CustomerPartner_Exclusions]-------------------------
-------------------------------------------------------------------------------------------------------
Truncate Table [Staging].[CustomerPartner_Exclusions]
-------------------------------------------------------------------------------------------------------
-------------------------Populate table [Staging].[CustomerPartner_Exclusions]-------------------------
-------------------------------------------------------------------------------------------------------
Insert Into [Staging].[CustomerPartner_Exclusions]
select	c.FanID,
		e.PartnerID,
		e.StartDate,
		e.EndDate 
from Staging.[CustomerPartner_ExclusionsRules] as e
inner join Relational.CustomerPaymentMethodsAvailable as p
	on	e.PaymentMethodAvailableID = p.PaymentMethodsAvailableID and
		p.EndDate is null
inner join Relational.Customer as c
	on p.FanID = c.FanID
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'WarehouseLoad_CustomerPartner_Exclusions' and
		TableSchemaName = 'Staging' and
		TableName = 'CustomerPartner_Exclusions' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  staging.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Staging.CustomerPartner_Exclusions)
where	StoredProcedureName = 'WarehouseLoad_CustomerPartner_Exclusions' and
		TableSchemaName = 'Staging' and
		TableName = 'CustomerPartner_Exclusions' and
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