
/********************************************************************************************
Name: Staging.UpdatingCAMEOCodes
Desc: Update and insert new rows from the latest CAMEO file
Auth: Rory Francis
Date: 16/08/2018

----------------------------------------------------------------------------------------------
 Change History

Jason Shipp 30/04/2020
	- Changed tables so they are temporary or in the Staging schema instead of Sandbox

*********************************************************************************************/

CREATE Procedure [Staging].[UpdatingCAMEOCodes]
as
	Begin

	/***************************************************************************************************
		Load current CAMEO data and create temp table for storing CAMEO changes
	***************************************************************************************************/

	TRUNCATE TABLE Warehouse.Staging.CAMEO_Staging

	INSERT INTO Warehouse.Staging.CAMEO_Staging (
		Postcode
		, GRE
		, GRN
		, CAMEO_CODE
		, CAMEO_CODE_GROUP
		, CAMEO_INTL
		, PostalSector
		, PostalDistrict
		, PostalArea
		, PCDSTATUS
	)
	SELECT 
		Postcode
		, GRE
		, GRN
		, CAMEO_CODE
		, CAMEO_CODE_GROUP
		, CAMEO_INTL
		, PostalSector
		, PostalDistrict
		, PostalArea
		, PCDSTATUS
	FROM Warehouse.Relational.CAMEO

	TRUNCATE TABLE Warehouse.Staging.Cameo_Updates

	/***************************************************************************************************
		Prepare data
	***************************************************************************************************/

		/*******************************************************************************
			Insert all values into temp table, removal quotes from import
		*******************************************************************************/

			If Object_ID('tempdb..#NewCameo') Is Not Null Drop Table #NewCameo
			Select Replace(Postcode_New,'"','') as Postcode_New
				 , Replace(GRE_New,'"','') as GRE_New
				 , Replace(GRN_New,'"','') as GRN_New
				 , Replace(CAMEO_CODE_New,'"','') as CAMEO_CODE_New
				 , Replace(CAMEO_CODE_GROUP_New,'"','') as CAMEO_CODE_GROUP_New
				 , Replace(CAMEO_INTL_New,'"','') as CAMEO_INTL_New
				 , Replace(PostalSector_New,'"','') as PostalSector_New
				 , Replace(PostalDistrict_New,'"','') as PostalDistrict_New
				 , Replace(PostalArea_New,'"','') as PostalArea_New
				 , Replace(Postcodestatusindicator_New,'"','') as Postcodestatusindicator_New
			Into #NewCameo
			From Warehouse.Staging.CAMEO_Import

/***************************************************************************************************
	Update existing data and insert new entries
***************************************************************************************************/

		/*******************************************************************************
			Update GRE
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_CODE_New != CAMEO_CODE
			--And CAMEO_CODE_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'GRN' as ColumnUpdated
				 , GRN as PreviousValue
				 , GRN_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where GRN_New != GRN
			And GRN_New != ''
			
			Update c
			Set GRN = GRN_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where GRN_New != GRN
			And GRN_New != ''

		/*******************************************************************************
			Update GRN
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_CODE_New != CAMEO_CODE
			--And CAMEO_CODE_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'GRE' as ColumnUpdated
				 , GRE as PreviousValue
				 , GRE_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where GRE_New != GRE
			And GRE_New != ''
			
			Update c
			Set GRE = GRE_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where GRE_New != GRE
			And GRE_New != ''

		/*******************************************************************************
			Update CAMEO_CODE
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_CODE_New != CAMEO_CODE
			--And CAMEO_CODE_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'CAMEO_CODE' as ColumnUpdated
				 , CAMEO_CODE as PreviousValue
				 , CAMEO_CODE_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_CODE_New != CAMEO_CODE
			And CAMEO_CODE_New != ''
			
			Update c
			Set CAMEO_CODE = CAMEO_CODE_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_CODE_New != CAMEO_CODE
			And CAMEO_CODE_New != ''

		/*******************************************************************************
			Update CAMEO_CODE_GROUP
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_CODE_GROUP_New != CAMEO_CODE_GROUP
			--And CAMEO_CODE_GROUP_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'CAMEO_CODE_GROUP' as ColumnUpdated
				 , CAMEO_CODE_GROUP as PreviousValue
				 , CAMEO_CODE_GROUP_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_CODE_GROUP_New != CAMEO_CODE_GROUP
			And CAMEO_CODE_GROUP_New != ''
			
			Update c
			Set CAMEO_CODE_GROUP = CAMEO_CODE_GROUP_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_CODE_GROUP_New != CAMEO_CODE_GROUP
			And CAMEO_CODE_GROUP_New != ''

		/*******************************************************************************
			Update CAMEO_INTL
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_INTL_New != CAMEO_INTL
			--And CAMEO_INTL_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'CAMEO_INTL' as ColumnUpdated
				 , CAMEO_INTL as PreviousValue
				 , CAMEO_INTL_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_INTL_New != CAMEO_INTL
			And CAMEO_INTL_New != ''
			
			Update c
			Set CAMEO_INTL = CAMEO_INTL_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where CAMEO_INTL_New != CAMEO_INTL
			And CAMEO_INTL_New != ''

		/*******************************************************************************
			Update PCDSTATUS
		*******************************************************************************/

			--Select Postcode
			--	 , PostalSector
			--	 , PostalArea
			--	 , CAMEO_CODE
			--	 , CAMEO_CODE_New
			--	 , CAMEO_CODE_GROUP
			--	 , CAMEO_CODE_GROUP_New
			--	 , CAMEO_INTL
			--	 , CAMEO_INTL_New
			--From Warehouse.Staging.CAMEO_Staging c
			--Full outer join #NewCameo nc
			--	on c.Postcode = nc.Postcode_New
			--Where CAMEO_INTL_New != CAMEO_INTL
			--And CAMEO_INTL_New != ''

			Insert Into Warehouse.Staging.Cameo_Updates
			Select Postcode
				 , 'PCDSTATUS' as ColumnUpdated
				 , PCDSTATUS as PreviousValue
				 , Postcodestatusindicator_New as NewValue
				 , GetDate() as UpdateDate
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where Postcodestatusindicator_New != PCDSTATUS
			And Postcodestatusindicator_New != ''
			
			Update c
			Set PCDSTATUS = Postcodestatusindicator_New
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where Postcodestatusindicator_New != PCDSTATUS
			And Postcodestatusindicator_New != ''

		/*******************************************************************************
			Insert new values
		*******************************************************************************/
			
			Insert Into Warehouse.Staging.CAMEO_Staging
			Select PostCode_New as Postcode
				 , GRE_New as GRE
				 , GRN_New as GRN
				 , CAMEO_CODE_New as CAMEO_CODE
				 , CAMEO_CODE_GROUP_New as CAMEO_CODE_GROUP
				 , CAMEO_INTL_New as CAMEO_INTL
				 , PostalSector_New as PostalSector
				 , PostalDistrict_New as PostalDistrict
				 , PostalArea_New as PostalArea
				 , Postcodestatusindicator_New as PCDSTATUS
			From Warehouse.Staging.CAMEO_Staging c
			Full outer join #NewCameo nc
				on c.Postcode = nc.Postcode_New
			Where c.Postcode Is Null
			And CAMEO_CODE_New != ''
			And CAMEO_CODE_GROUP_New != ''
			And CAMEO_INTL_New != ''

	/*******************************************************************************
		Refresh live table(s)
	*******************************************************************************/

	-- TRUNCATE TABLE Warehouse.Relational.Cameo

	--INSERT INTO Warehouse.Relational.Cameo (
	--	Postcode
	--	, GRE
	--	, GRN
	--	, CAMEO_CODE
	--	, CAMEO_CODE_GROUP
	--	, CAMEO_INTL
	--	, PostalSector
	--	, PostalDistrict
	--	, PostalArea
	--	, PCDSTATUS
	--)
	--SELECT 
	--	Postcode
	--	, GRE
	--	, GRN
	--	, CAMEO_CODE
	--	, CAMEO_CODE_GROUP
	--	, CAMEO_INTL
	--	, PostalSector
	--	, PostalDistrict
	--	, PostalArea
	--	, PCDSTATUS
	--FROM Warehouse.Staging.CAMEO_Staging

	---- Cleanup

	-- TRUNCATE TABLE Warehouse.Staging.Cameo_Import

	---- Also update the following tables if we get new data

	--SELECT * FROM Warehouse.Relational.CAMEO_CODE
	--SELECT * FROM Warehouse.Relational.CAMEO_CODE_GROUP
	--SELECT * FROM  Warehouse.Relational.CAMEO_SocialClassDescription
	
END