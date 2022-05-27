/*--------------------------------------

	Author:		Stuart Barnley

	Date:		2nd November 2017

	Purpose:	Adding new Warehouse Partner Info.


---------------------------------------*/
CREATE Procedure [Staging].[AddingaNewPartner] (	@PID int,
												@BID int,
												@SDate Date
											)
With Execute as Owner as

Declare		@PartnerID int = @PID,
			@BrandID int = @BID,
			@StartDate DATE = @SDate

/*-------------------------------------------------------*/
 ----------------Updating Relational.Partner---------------
/*-------------------------------------------------------*/

INSERT INTO Warehouse.Relational.Partner
SELECT	(Select  Max(SequenceNumber) From Warehouse.Relational.Partner)+1 as SequenceNumber,
	p.ID as PartnerID,
	p.Name as PartnerName,
	b.BrandID as BrandID,
	b.BrandName as BrandName,
	0 as CurrentlyActive
From	slc_report.dbo.partner as p
Left Outer Join warehouse.relational.partner as a
		on p.ID = a.PartnerID,
		warehouse.relational.brand as b
Where	@PartnerID = p.ID and
		@BrandID = b.BrandID and
		a.PartnerID is null

Select 'Warehouse.Relational.Partner' as [TableName],*
From Warehouse.relational.Partner Where PartnerID = @PartnerID

/*-------------------------------------------------------*/
 -----------Updating Relational.Partner_CBPDates----------
/*-------------------------------------------------------*/

INSERT INTO Warehouse.Relational.Partner_CBPDates

Select a.*
From
	(SELECT	@PartnerID as PartnerID,
			@StartDate as Scheme_StartDate,
			CAST(NULL AS DATE) as Scheme_EndDate,
			0 as Coalition_Member
	) a
Left Outer join Warehouse.Relational.Partner_CBPDates as b
	on a.PartnerID = b.PartnerID and
		(	b.Scheme_EndDate is null or
			b.Scheme_EndDate >= getdate())
Where b.PartnerID is null

Select 'Warehouse.Relational.Partner_CBPDates' as [TableName],*
From Warehouse.Relational.Partner_CBPDates Where PartnerID = @PartnerID	


/*---------------------------------------------------*/
 --------Create Partners_IncFuture Table Entry--------
/*---------------------------------------------------*/
INSERT INTO Warehouse.Staging.Partners_IncFuture
SELECT	p.ID as PartnerID,
	p.Name as PartnerName,
	b.BrandID as BrandID,
	b.BrandName as BrandName
From	slc_report.dbo.partner as p
Left Outer Join Warehouse.Staging.Partners_IncFuture as a
		on p.ID = a.PartnerID,
		warehouse.relational.brand as b
Where	@PartnerID = p.ID and
		@BrandID = b.BrandID and
		a.PartnerID is null

Select 'Warehouse.Staging.Partners_IncFuture' as [TableName],*
From Warehouse.Staging.Partners_IncFuture Where PartnerID = @PartnerID

/*----------------------------------------------------------------------------------*/
 ------Create [Segmentation].[ROC_Shopper_Segment_Partner_Settings] Table Entry------
/*----------------------------------------------------------------------------------*/

Insert into [Segmentation].[ROC_Shopper_Segment_Partner_Settings]
Select	@PartnerID,
		SS_AcquireLength,
		SS_LapsersDefinition,
		Getdate() as StartDate,
		NUll as EndDate,
		0 as AutoRun
From warehouse.[Relational].[MRF_ShopperSegmentDetails] as a
left outer join [Segmentation].[ROC_Shopper_Segment_Partner_Settings] as b
	on a.PartnerID = b.PartnerID and
		(b.EndDate is null or b.EndDate >= getdate())
Where	a.partnerid = @PartnerID and
		b.PartnerID is null

Select '[Segmentation].[ROC_Shopper_Segment_Partner_Settings]' as [TableName],*
From [Segmentation].[ROC_Shopper_Segment_Partner_Settings] Where PartnerID = @PartnerID

/*----------------------------------------------------------------------------------*/
 -----Create [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2] Table Entry-----
/*----------------------------------------------------------------------------------*/
Insert into [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2]
Select	@PartnerID,
		SS_AcquireLength,
		100 as Acquire_Pct,
		SS_LapsersDefinition,
		Getdate() as StartDate,
		NUll as EndDate,
		0 as AutoRun
From warehouse.[Relational].[MRF_ShopperSegmentDetails] as a
left outer join [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2] as b
	on a.PartnerID = b.PartnerID and
		(b.EndDate is null or b.EndDate >= getdate())
Where	a.partnerid = @PartnerID and
		b.PartnerID is null

Select '[Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2]' as [TableName],*
From [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2] Where PartnerID = @PartnerID
/*----------------------------------------------------------------------------------*/
 -----Create [Segmentation].[ROC_Shopper_Segment_Partner_Settingsv2] Table Entry-----
/*----------------------------------------------------------------------------------*/
Insert into nfi.[Segmentation].[PartnerSettings]
Select	@PartnerID,
		SS_LapsersDefinition,
		SS_AcquireLength,
		0,
		Getdate() as StartDate,
		NUll as EndDate,
		0 as CtrlGrp,
		0 as AutomaticRun
From warehouse.[Relational].[MRF_ShopperSegmentDetails] as a
left outer join nfi.[Segmentation].[PartnerSettings] as b
	on a.PartnerID = b.PartnerID and
		(b.EndDate is null or b.EndDate >= getdate())
Where	a.partnerid = @PartnerID and
		b.PartnerID is null

Select 'nfi.[Segmentation].[PartnerSettings]' as [TableName],*
From nfi.[Segmentation].[PartnerSettings] Where PartnerID = @PartnerID