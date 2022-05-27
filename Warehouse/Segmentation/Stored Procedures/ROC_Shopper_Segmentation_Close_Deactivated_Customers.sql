/*
	Author:			Stuart Barnley

	Date:			13th April 2016

	Purpose:		To EndDate any Shopper Segments where the customer is no longer active on the
					MyRewards scheme


*/

CREATE Procedure [Segmentation].[ROC_Shopper_Segmentation_Close_Deactivated_Customers]
With Execute as Owner
As

Declare @TableName varchar(40)
	  , @EndDate DATETIME = Dateadd(day,DATEDIFF(dd, 0, GETDATE())-0,0)
	  
Set @TableName = 'Roc_Shopper_Segment_Members'

--------------------------------------------------------------------------------------
----------------------------Write Entry to Joblog_Temp--------------------------------
--------------------------------------------------------------------------------------
INSERT INTO Staging.JobLog_Temp
SELECT	StoredProcedureName = 'ROC_Shopper_Segmentation_Close_Deactivated_Customers',
	TableSchemaName = 'Segmentation',
	TableName = @TableName,
	StartDate = GETDATE(),
	EndDate = NULL,
	TableRowCount  = NULL,
	AppendReload = 'U'

--------------------------------------------------------------------------------------
----------------------------Create Table of Deactivated Customers---------------------
--------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Deactivated') IS NOT NULL DROP TABLE #Deactivated

Select FanID
into #Deactivated
From Relational.Customer as c
Where c.CurrentlyActive = 0

--------------------------------------------------------------------------------------
----------------------------Create Table of Deactivated Customers---------------------
--------------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#Updates') IS NOT NULL DROP TABLE #Updates

Select m.ID
Into #Updates
From #Deactivated as d
inner join Segmentation.Roc_Shopper_Segment_Members as m
	on	d.FanID = m.FanID and
		m.EndDate is null

--------------------------------------------------------------------------------------
----------------------------Create Table of Deactivated Customers---------------------
--------------------------------------------------------------------------------------
Update Segmentation.Roc_Shopper_Segment_Members
Set EndDate = @EndDate
Where ID in (Select ID From #Updates)

--------------------------------------------------------------------------------------------
------------------------Write Entry to Joblog_Temp and update Joblog------------------------
--------------------------------------------------------------------------------------------

UPDATE	Staging.JobLog_Temp
SET		EndDate = GETDATE(),
		TableRowCount = (Select Count(*) From #Updates)
WHERE	StoredProcedureName = 'ROC_Shopper_Segmentation_Close_Deactivated_Customers' 
	AND TableSchemaName = 'Segmentation'
	AND TableName = @TableName
	AND EndDate IS NULL


INSERT INTO Staging.JobLog
SELECT	StoredProcedureName,
	TableSchemaName,
	TableName,
	StartDate,
	EndDate,
	TableRowCount,
	AppendReload
FROM Staging.JobLog_Temp

TRUNCATE TABLE Staging.JobLog_Temp