/*

	Author:		Stuart Barnley

	Date:		1st September 2017

	Purpose:	To update an OIN by setting it to rejected by RBSG, they are looking to 
				submit in bulk therefore this SP will be called by bulk process


*/

CREATE Procedure [Staging].[DirectDebit_Sun_Removals_1ofBulk] (@SUN int)
With Execute as Owner
As
--------------------------------------------------------------------------------------
-------------------------Populate Parameters for SP call------------------------------
--------------------------------------------------------------------------------------
Declare @SDate date = GetDate(),
		@EDate date,
		@O  int = @SUN,
		@Supplier varchar (250) = NULL,
		@SupplierCat varchar (250) = NULL
Set @EDate = Dateadd(day,-1,@SDate)

Set @Supplier = (	Select	b.SupplierName
					From warehouse.Staging.DirectDebit_OINs as a
					inner join warehouse.Relational.DD_DataDictionary_Suppliers as b
						on a.DirectDebit_SupplierID = b.SupplierID
					 Where	OIN = @O and
							EndDate is null and
							DirectDebit_StatusID = 4 and
							StartDate < @SDate
				)

Set @SupplierCat = (	Select	b.Ext_SupplierCategory
					From warehouse.Staging.DirectDebit_OINs as a
					inner join warehouse.Relational.DD_DataDictionary_Suppliers as b
						on a.DirectDebit_SupplierID = b.SupplierID
					 Where	OIN = @O and
							EndDate is null and
							DirectDebit_StatusID = 4 and
							StartDate < @SDate
				)

If @Supplier is not null
	Begin
			--------------------------------------------------------------------------------------
			---------------------------------------Make SP Call-----------------------------------
			--------------------------------------------------------------------------------------

			EXEC Staging.DirectDebit_OIN_Update
			@OIN = @O,	
			@StartDate = @SDate,
			@EndDate = @EDate,
			@DirectDebit_StatusID = 5,
			@SupplierName = @Supplier,
			@Ext_SupplierCategory = @SupplierCat,
			@SupplierWildcard = '',
			@SupplierRefusedByRBSG = 0,
			@InternalCategoryID = 1,
			@RBSCategoryID = 1

			Update a
			Set RemovalDate = @SDate
			From Staging.RBSGRemovalsBulk as a
			Where	OIN = @O and
					RemovalDate Is Null
	End
