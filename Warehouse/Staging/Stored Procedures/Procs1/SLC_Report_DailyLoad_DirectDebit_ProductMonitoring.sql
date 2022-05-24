CREATE Procedure [Staging].[SLC_Report_DailyLoad_DirectDebit_ProductMonitoring]
With Execute as Owner
As

If Getdate() < '2017-07-31'
Begin
	Exec Warehouse.Staging.SLC_Report_DailyLoad_DirectDebit60days
	Exec Warehouse.Staging.SLC_Report_DailyLoad_DirectDebit120days
End 
If Getdate() >= '2017-07-31'
Begin
	Exec Warehouse.Staging.SLC_Report_DailyLoad_DirectDebit60days_2_0
	Exec Warehouse.Staging.SLC_Report_DailyLoad_DirectDebit120days_2_0
End 
