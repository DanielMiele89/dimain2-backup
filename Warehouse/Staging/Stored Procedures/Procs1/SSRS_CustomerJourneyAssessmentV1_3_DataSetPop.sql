/*
	Author:			Stuart Barnley
	Date:			09th April 2014
	Description:	As the customer base increases it makes it more and more difficult to run reports on 
					the go,	therefore this stored procedure populates the tables that are used for the 
					Customer Journey Report.

	Note:			This will be added to the ETL so will run daily.
*/

CREATE Procedure [Staging].[SSRS_CustomerJourneyAssessmentV1_3_DataSetPop]
As
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop',
		TableSchemaName = 'Staging',
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------*/

Truncate Table Staging.SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus

---------------------------------------------------------------------------------------------------------
-------------------------------------Pull Customer Journey Data------------------------------------------
---------------------------------------------------------------------------------------------------------
Insert Into Staging.SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus
select	Distinct 
		c.FanID,
		Case
			When c.POC_Customer = 1 then 'POC'
			Else 'Activated Since Full Launch'
		End as POC_Customer,
		Case
			When c.POC_Customer = 1 then 'POC'
			Else 'New'
		End as CustomerType,
		Case
			When c.POC_Customer = 1 then 1
			Else 0
		End as POCCustomers,
		cj.CustomerJourneyStatus,
		cj.LapsFlag,
		EmailEngaged,
		Case
			When c.POC_Customer = 1 and EmailEngaged =1 then 1
			Else 0
		End as POC_EmailEngaged,
		Case
			When c.POC_Customer = 0 and EmailEngaged =1 then 1
			Else 0
		End as NonPOC_EmailEngaged

from	Relational.Customer as c
inner join Relational.customerJourney as CJ
	on c.FanID = cj.FanID and cj.EndDate is null
inner join [Relational].[Customer_EmailEngagement] as CEE
	on c.FanID = CEE.FanID and cee.EndDate  is null
Where c.CurrentlyActive = 1 and left(cj.Shortcode,1) <> 'D'
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(1) from Staging.SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus)
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop',
		TableSchemaName = 'Staging',
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

/*--------------------------------------------------------------------------------------------------
--------------------------------------Create Rolled up Dataset--------------------------------------
----------------------------------------------------------------------------------------------------*/
--Create Table Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp (CustomerJourneyStatus varchar(24),EmailEngaged tinyint,CustomerCount int,POCCount int,FullLaunch int)
Truncate table Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp
Insert into Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp
select	CustomerJourneyStatus,
		EmailEngaged,
		Count(*) CustomerCount,
		Sum(POCCustomers) as POCCount,
		Sum(Case
				When POCCustomers = 1 then 0
				Else 1
			End) as FullLaunch
from Staging.SSRS_CustomerJourneyAssessmentV1_2_ActivatedCustomers_CJStatus
Group By CustomerJourneyStatus,
		EmailEngaged

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(1) from Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp)
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUp' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop',
		TableSchemaName = 'Staging',
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
/*--------------------------------------------------------------------------------------------------
-----------------------------Create by Type Rolled Up Data------------------------------------------
----------------------------------------------------------------------------------------------------*/
Truncate Table [Staging].[SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType]
Insert into [Staging].[SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType]
select	CustomerJourneyStatus,
		'POC' as [Type],
		Sum(POCCount) as CustomerCount,
		Sum(Case
				When emailengaged = 1 then POCCount
				Else 0
			End) as Engaged

from [Staging].[SSRS_CustomerJourneyAssessmentV1_2_RolledUp]
Group By CustomerJourneyStatus
Union All
select	CustomerJourneyStatus,
		'Full Launch' as [Type],
		Sum(FullLaunch) as CustomerCount,
		Sum(Case
				When emailengaged = 1 then FullLaunch
				Else 0
			End) as Engaged

from [Staging].[SSRS_CustomerJourneyAssessmentV1_2_RolledUp]
Group By CustomerJourneyStatus
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(1) from Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType)
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'Staging.SSRS_CustomerJourneyAssessmentV1_2_RolledUpByType' and
		TableRowCount is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop',
		TableSchemaName = 'Staging',
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_RunDate',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'


---------------------------------------------------------------------------------------------------------
-------------------------------------------Store Data Date-----------------------------------------------
---------------------------------------------------------------------------------------------------------
Truncate Table Staging.SSRS_CustomerJourneyAssessmentV1_2_RunDate
Insert into Staging.SSRS_CustomerJourneyAssessmentV1_2_RunDate
Select Cast(Getdate() as date) as ReportRunDate
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_RunDate' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		TableRowCount = (Select Count(1) from Staging.SSRS_CustomerJourneyAssessmentV1_2_RunDate)
where	StoredProcedureName = 'SSRS_CustomerJourneyAssessmentV1_3_DataSetPop' and
		TableSchemaName = 'Staging' and
		TableName = 'SSRS_CustomerJourneyAssessmentV1_2_RunDate' and
		TableRowCount is null

/*--------------------------------------------------------------------------------------------------
-------------------------------------Update JobLog from JobLog_Temp---------------------------------
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

TRUNCATE TABLE staging.JobLog_Temp
