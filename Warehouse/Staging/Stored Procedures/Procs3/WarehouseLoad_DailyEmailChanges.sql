
CREATE Procedure Staging.WarehouseLoad_DailyEmailChanges
As
--------------------------------------------------------------------------------------------------------
-----------------------------------Log Credit Card Welcome Emails---------------------------------------
--------------------------------------------------------------------------------------------------------
--Create Table Warehouse.InsightArchive.FanSFDDailyUploadData_Welcomes (	ID int identity(1,1) not null,
--																		FanID int not null,
--																		WelcomeEmailCode Char(2),
--																		DataDay Date,
--																		Primary Key (ID)
--																		)
--Truncate Table Warehouse.InsightArchive.FanSFDDailyUploadData_Welcomes
Insert into Warehouse.InsightArchive.FanSFDDailyUploadData_Welcomes
select FanID,WelcomeEmailCode,Cast(Getdate()as date)
From slc_report.dbo.FanSFDDailyUploadData
Where WelcomeEmailCode is Not null

--------------------------------------------------------------------------------------------------------
-----------------------------------Log Credit Card Welcome Emails---------------------------------------
--------------------------------------------------------------------------------------------------------
--Truncate Table Warehouse.InsightArchive.FanSFDDailyUploadData_Welcomes
Insert into Warehouse.InsightArchive.[SLC_Report_DailyLoad_Phase2DataFields]
Select * ,Cast(getdate() as date) as date
from Warehouse.Staging.SLC_Report_DailyLoad_Phase2DataFields as a
Where Len(FirstEarnType) > 1 or homemover = 1 or Reached5GBP between '2015-11-20' and '2015-11-22'