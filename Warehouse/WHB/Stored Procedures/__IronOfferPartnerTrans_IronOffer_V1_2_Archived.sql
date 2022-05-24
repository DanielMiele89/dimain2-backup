/*
Author:		Stuart Barnley	
Date:		07th February 2014
Purpose:	Full load of IronOffer table, seperated from IronOfferMember due to the size of the 
			IOM table
			
		
Update:		04-11-2014 SB - Update to set AboveBase = 0 where non-core base offer
			17-06-2015 SB - Updated to only include CBP offers
			28-09-2018 RF - Updated to include TopCashBackRate for valid offers that happen to include 'Test' in their name
*/
CREATE PROCEDURE [WHB].[__IronOfferPartnerTrans_IronOffer_V1_2_Archived]

As

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

DECLARE @ERROR_NUMBER INT, @ERROR_SEVERITY INT, @ERROR_STATE INT, @ERROR_PROCEDURE VARCHAR(100), @ERROR_LINE INT, @ERROR_MESSAGE VARCHAR(200);

BEGIN TRY

	/*--------------------------------------------------------------------------------------------------
	-----------------------------Write entry to JobLog Table--------------------------------------------
	----------------------------------------------------------------------------------------------------*/

	Insert into staging.JobLog_Temp
	Select	StoredProcedureName = OBJECT_NAME(@@PROCID),
			TableSchemaName = 'Relational',
			TableName = 'IronOffer',
			StartDate = GETDATE(),
			EndDate = null,
			TableRowCount  = null,
			AppendReload = 'R'

	--------------------------------------------------------------------------------
	---------------Copy slc_report.dbo.IronOffer into table -------------------------
	---------------------------------------------------------------------------------
	Truncate Table Relational.IronOffer

	Insert Into   Relational.IronOffer
	SELECT Cast(i.[ID] as Int)							as IronOfferID
		  ,Cast(I.[Name] as nvarchar(200))				as IronOfferName
		  ,Cast(I.[StartDate] as Datetime)				as StartDate
		  ,Cast(I.[EndDate] as Datetime)				as EndDate
		  ,Cast(I.[PartnerID] as Int)					as PartnerID
		  ,Cast(I.[IsAboveTheLine] as bit)				as IsAboveTheLine
		  ,Cast(I.[AutoAddToNewRegistrants] as bit)		as AutoAddToNewRegistrants
		  ,Cast(I.[IsDefaultCollateral] as bit)			as IsDefaultCollateral
		  ,Cast(I.[IsSignedOff] as bit)					as IsSignedOff
		  ,Cast(I.[AreEligibleMembersCommitted] as bit)	as AreEligibleMembersCommitted
		  ,Cast(I.[AreControlMembersCommitted] as bit)	as AreControlMembersCommitted
		  ,Cast(I.[IsTriggerOffer] as bit)				as IsTriggerOffer
		  ,Cast(Case
					When pbo.OfferID IS NULL and pob.OfferID is null then 0
					Else 1
				End as Bit) as Continuation
		  ,Case
				When i.name in ('Above the line','Above the line Collateral','Default','Default Collateral') then 0
				When i.name Like '%MaterCard%' then 0
				When i.name Like '%Test%' And i.Name NOT LIKE '%/%Test%' then 0
				--When i.IsSignedOff = 0 then 0
				Else NULL
			End as TopCashBackRate
		  ,Case
				When i.name in ('Above the line','Above the line Collateral','Default','Default Collateral') then 0
				When i.name Like '%MaterCard%' then 0
				When i.name Like '%Test%' And i.Name NOT LIKE '%/%Test%' then 0
				When i.IsSignedOff = 0 then 0
				When pbo.OfferID is not null then 0
				When pob.OfferID is not null then 0
				Else NULL
			End as AboveBase,
		   Case
				When Club.Clubs is null then 'None'
				When Club.Clubs = 1 and Club.ClubID = 132 then 'Natwest'
				When Club.Clubs = 1 and Club.ClubID = 138 then 'RBS'
				When Club.Clubs = 2 then 'Both'
				Else NULL
			End as Clubs,
			Case
				When i.StartDate <= 'Aug 01, 2013' then (Select [Description] from [Staging].[IronOffer_Campaign_Type_Lookup] Where CampaignTypeID = 2)
				When pbo.OfferID IS NOT NULL or pob.OfferID is not null then (Select [Description] from [Staging].[IronOffer_Campaign_Type_Lookup] Where CampaignTypeID = 1)
				Else (Select [Description] from [Staging].[IronOffer_Campaign_Type_Lookup] Where CampaignTypeID = 5)
			End as CampaignType
	FROM [SLC_Report].[dbo].[IronOffer] as I with (nolock)
	Left Outer Join relational.Partner_BaseOffer as pbo
		on I.ID = pbo.OfferID
	Left Outer join 
		(select Distinct OfferID,CashbackRateNumeric From relational.PartnerOffers_Base) as pob
			on i.id = pob.OfferID
	Left Outer Join
		(Select IronOfferID,Max(Case When ClubID in (132) then 1 else 0 End)+Max(Case When ClubID in (138) then 1 else 0 End) as Clubs, Max(ClubID)as ClubID
			from slc_report.dbo.IronOfferClub
		 Group by IronOfferID) as Club
			on i.ID = Club.IronOfferID

	/*--------------------------------------------------------------------------------------------------
	-----------------------------------------Fetch Cashback Rate ---------------------------------------
	--------------------------------------------------------------------------------------------------*/
	Update relational.IronOffer
	Set TopCashbackRate = TCBR
	From relational.ironoffer as i
	inner join 
	(Select IronOfferID,Max(CommissionRate) as TCBR
	from relational.IronOffer as i
	inner join slc_report.dbo.PartnerCommissionRule as pcr
		on i.IronOfferID = pcr.RequiredIronOfferID
	Where Status = 1 and TypeID = 1 and TopCashbackRate is null
	Group by IronOfferID
	) as a 
		on i.ironofferid = a.ironofferid
	/*--------------------------------------------------------------------------------------------------
	-------------------------------Work out if cashback rate above base---------------------------------
	--------------------------------------------------------------------------------------------------*/
	Update relational.ironoffer 
	Set AboveBase = ABase
	From relational.ironoffer as i
	inner join
	(Select I.IronOfferID,
			Case
				When i.IronOfferName in ('Above the line','Above the line Collateral','Default','Default Collateral') then 0
				When i.IronOfferName Like '%MaterCard%' then 0
				When i.IronOfferName Like '%Test%' And i.IronOfferName NOT LIKE '%/%Test%' then 0
				When i.IsSignedOff = 0 then 0
				When pbo.AboveBase is not null then pbo.AboveBase
				When pob.PartnerID is not null and i.TopCashBackRate > (100*pob.CashBackRateNumeric) then 1
				When pob.PartnerID is not null and i.TopCashBackRate <= (100*pob.CashBackRateNumeric) then 0
				When pbo.IronOfferID is null AND pob.PartnerID is null then 1
				Else NULL
			End as ABase
	from relational.IronOffer as i
	Left outer join Staging.IronOffer_Campaign_HTM_PreLaunch as pbo
		on i.IronOfferID = pbo.IronOfferID
	Left Outer join 
		(select Distinct PartnerID,CashbackRateNumeric,StartDate,EndDate 
				From relational.PartnerOffers_Base) as pob
				on	i.PartnerID = pob.PartnerID and
					pob.StartDate <= i.StartDate and
					(pob.EndDate >= i.StartDate or pob.EndDate is null) 
	Where i.Abovebase is null
	) as a
		on i.IronOfferID = a.IronOfferID
	/*--------------------------------------------------------------------------------------------------
	-----------------------------------------Work Out Campaign Type-------------------------------------
	--------------------------------------------------------------------------------------------------*/
	Update relational.ironoffer
	Set CampaignType = ctl.[Description]
	from relational.ironoffer as i
	inner join relational.IronOffer_Campaign_HTM as htm
		on i.IronOfferID = htm.IronOfferID
	inner join [Staging].[IronOffer_Campaign_Type] as ct
		on htm.ClientServicesRef = ct.ClientServicesRef
	inner join [Staging].[IronOffer_Campaign_Type_Lookup] as ctl
		on ct.CampaignTypeID = ctl.CampaignTypeID
	/*--------------------------------------------------------------------------------------------------
	----------------------------Set Above Base Offers for non-core base offers--------------------------
	--------------------------------------------------------------------------------------------------*/
	Update relational.ironoffer
	Set AboveBase = 0
	from relational.ironoffer as i
	inner join [Relational].[Partner_NonCoreBaseOffer] as n
		on i.IronOfferID = n.IronOfferID
	/*--------------------------------------------------------------------------------------------------
	---------------------------------------Remove non CBP offers----------------------------------------
	--------------------------------------------------------------------------------------------------*/
	Delete From relational.ironoffer
	From relational.ironoffer as i
	left outer join SLC_Report..IronOfferClub as ioc
		on	i.IronOfferID = ioc.IronOfferID and
			ioc.ClubID in (132,138)
	Where ioc.IronOfferID is null
	/*--------------------------------------------------------------------------------------------------
	-------------------------------Remove expired unsigned off offers-----------------------------------
	--------------------------------------------------------------------------------------------------*/
	Delete From relational.ironoffer
	From relational.ironoffer as i
	Where	i.IsAboveTheLine = 0 and
			i.IsDefaultCollateral = 0 and
			i.IsSignedOff = 0 and
			i.EndDate < Cast(getdate() as date) and
			i.IsTriggerOffer = 0
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with End Date-------------------------------
	----------------------------------------------------------------------------------------------------*/
	Update  staging.JobLog_Temp
	Set		EndDate = GETDATE()
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'IronOffer' and
			EndDate is null
	/*--------------------------------------------------------------------------------------------------
	---------------------------Update entry in JobLog Table with Row Count------------------------------
	----------------------------------------------------------------------------------------------------*/
	--Count run seperately as when table grows this as a task on its own may take several minutes and we do
	--not want it included in table creation times
	Update  staging.JobLog_Temp
	Set		TableRowCount = (Select COUNT(*) from Relational.IronOffer)
	where	StoredProcedureName = OBJECT_NAME(@@PROCID) and
			TableSchemaName = 'Relational' and
			TableName = 'IronOffer' and
			TableRowCount is null
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------------------
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
	

	RETURN 0; -- normal exit here

END TRY
BEGIN CATCH		
		
	-- Grab the error details
	SELECT  
		@ERROR_NUMBER = ERROR_NUMBER(), 
		@ERROR_SEVERITY = ERROR_SEVERITY(), 
		@ERROR_STATE = ERROR_STATE(), 
		@ERROR_PROCEDURE = ERROR_PROCEDURE(),  
		@ERROR_LINE = ERROR_LINE(),   
		@ERROR_MESSAGE = ERROR_MESSAGE();
	SET @ERROR_PROCEDURE = ISNULL(@ERROR_PROCEDURE, OBJECT_NAME(@@PROCID))

	IF @@TRANCOUNT > 0 ROLLBACK TRAN;
			
	-- Insert the error into the ErrorLog
	INSERT INTO Staging.ErrorLog (ErrorDate, ProcedureName, ErrorLine, ErrorMessage, ErrorNumber, ErrorSeverity, ErrorState)
	VALUES (GETDATE(), @ERROR_PROCEDURE, @ERROR_LINE, @ERROR_MESSAGE, @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE);	

	-- Regenerate an error to return to caller
	SET @ERROR_MESSAGE = 'Error ' + CAST(@ERROR_NUMBER AS VARCHAR(6)) + ' in [' + @ERROR_PROCEDURE + '] at Line ' + CAST(@ERROR_LINE AS VARCHAR(6)) + '; ' + @ERROR_MESSAGE; 
	RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE);  

	-- Return a failure
	RETURN -1;
END CATCH

RETURN 0; -- should never run