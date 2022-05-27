CREATE Procedure [Staging].[PennyforLondon_ETL]
WITH EXECUTE AS OWNER
as

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog
Select	StoredProcedureName = 'PennyforLondon ETL - Start',
		TableSchemaName = '',
		TableName = '',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = ''

/*--------------------------------------------------------------------------------------------------
------------------------------------------------Call SPS--------------------------------------------
----------------------------------------------------------------------------------------------------*/
Exec [Staging].[PennyforLondon_Customer_DeactivatedandOptoutDates] --**Must be run before customer table built**---
Exec [Staging].[PennyforLondon_Customer]
Exec Staging.PennyForLondon_Customer_Updates
Exec [Staging].[PennyforLondon_Customer_DonationPreferences_PfL]
Exec [Staging].[PennyforLondon_CardActivations]
Exec [Staging].[PennyforLondon_DonationFilesStatus_PfL]
Exec [Staging].[PennyforLondon_DonationFiles_PfL]
Exec [Staging].[PennyforLondon_DonationStatus_PfL]
Exec [Staging].[PennyforLondon_Donations_PfL]
Exec [Staging].[PennyforLondon_PartnerV1_1]
Exec [Staging].[PennyforLondon_Outlet]
--Exec [Staging].[PennyforLondon_PartnerTrans]
Exec [Staging].[PennyforLondon_AccountActivityExceptionReasons_PfL]
Exec [Staging].[PennyforLondon_AccountActivityExceptions_PfL]
Exec [Staging].[PennyforLondon_RedeemItems]
Exec [Staging].[PennyforLondon_RedeemItems_Refunds]
Exec [Staging].[PennyforLondon_PartnerTrans_TFL]
Exec [Staging].[PennyforLondon_PartnerTrans]

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog
Select	StoredProcedureName = 'PennyforLondon ETL - End',
		TableSchemaName = '',
		TableName = '',
		StartDate = Getdate(),
		EndDate = Getdate(),
		TableRowCount  = null,
		AppendReload = ''

--select * from slc_report.dbo.partner


--Select * from Relational.Joblog
----Where Name = 'Outlet'

--Select * from SchemeWarehouse.relational.PartnerTrans