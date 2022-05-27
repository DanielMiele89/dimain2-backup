/*
	Author:			Stuart Barnley
	Date:			29/10/2014
	Description:	This Stored procedure creates the table Customer_DonationPreferences_PfL

	Notes:

*/

CREATE PROCEDURE [Staging].[PennyforLondon_Customer_DonationPreferences_PfL]
WITH EXECUTE AS OWNER
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Customer_DonationPreferences_PfL',
		TableSchemaName = 'Relational',
		TableName = 'Customer_DonationPreferences_PfL',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'
----------------------------------------------------------------------------------------
-------------------Populate Table - Customer_DonationPreferences_PfL--------------------
----------------------------------------------------------------------------------------
Truncate Table Relational.Customer_DonationPreferences_PfL
Insert into Relational.Customer_DonationPreferences_PfL
Select 	 --ID as DonationPreferences_PfL_ID
		 MemberID as FanID
		,PrimaryPANID
		,[DonationAmount]
		,[FailedDonationsCount]
		,[MaxMonthlyDonation]
		,[GiftAid]
		,[EmployerMatchingCode]
From SLC_Report.pfl.[DonationPreferences] as dp
inner join Relational.Customer as c
	on dp.MemberID = c.FanID

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Customer_DonationPreferences_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_DonationPreferences_PfL' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with Row Count------------------------------
----------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Customer_DonationPreferences_PfL)
where	StoredProcedureName = 'Penny4London_Customer_DonationPreferences_PfL' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer_DonationPreferences_PfL' and
		TableRowCount is null
		
Insert into Relational.JobLog
select [StoredProcedureName],
	[TableSchemaName],
	[TableName],
	[StartDate],
	[EndDate],
	[TableRowCount],
	[AppendReload]
from Relational.JobLog_Temp

TRUNCATE TABLE Relational.JobLog_Temp
End