/******************************************************************************
Author: Jason Shipp
Created: 09/03/2018
Purpose: 
	- Load Warehouse PartnerIDs to run segmentations for
	- Load validation of retailer offers to be segmented
		 
------------------------------------------------------------------------------
Modification History

Jason Shipp 10/04/2019
	-- Added partner settings for MFDD partners

******************************************************************************/
CREATE PROCEDURE [Staging].[ControlSetup_RBS_Load_Partners_To_Segment]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	-- Load combined POS partner and MFDD partner settings

	If object_id('tempdb..#PartnerSettings') is not null drop table #PartnerSettings;

	Select
		dd.PartnerID
		, dd.Acquire
		, dd.Lapsed
		, dd.Shopper
		, dd.StartDate
		, dd.EndDate
		, dd.AutoRun
	Into #PartnerSettings
	From Warehouse.Segmentation.PartnerSettings_DD dd

	Union All

	Select
		s.PartnerID
		, s.Acquire
		, s.Lapsed
		, s.Shopper
		, s.StartDate
		, s.EndDate
		, s.AutoRun
	From Warehouse.Segmentation.ROC_Shopper_Segment_Partner_Settings s
	Where not exists ( -- Logic to avoid duplication
		Select null from Warehouse.Segmentation.PartnerSettings_DD dd
		Where
			s.PartnerID = dd.PartnerID
			and (s.StartDate <= dd.EndDate or dd.EndDate is null)
			and (s.EndDate >= dd.StartDate or s.EndDate is null)
	);

	Create Nonclustered INDEX ix_PartnerSettings ON #PartnerSettings (PartnerID, StartDate);

	/******************************************************************************
	Load PartnerIDs to run Segmentations for

	Create table for storing results:

	CREATE TABLE Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse
		(RowNo INT
		, PartnerID INT
		, StartDate DATE
		, EndDate DATE
		, Segment VARCHAR(50)
		, CONSTRAINT PK_ControlSetup_PartnersToSeg_Warehouse PRIMARY KEY CLUSTERED (RowNo, PartnerID, StartDate, EndDate)
		)
	******************************************************************************/

	Truncate table Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse;

	-- Load PartnerIDs
	Insert into Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse
	Select Distinct
		a.RowNo
		, b.PartneriD
		, a.StartDate
		, a.EndDate
		, a.Segment
	From Warehouse.Staging.PartnerControlgroupIDs_RBSG a
	Inner join #PartnerSettings b
		on a.partnerid = b.partnerID
	Inner join warehouse.relational.[partner] p
		on b.PartnerID = p.PartnerID;
	
	-- Load more PartnerIDs
	Insert into Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse
	Select	Distinct 
		b.RowNo
		, RBS_P.PartnerID
		, b.StartDate
		, b.EndDate
		, b.Segment
	From Warehouse.Staging.PartnerControlgroupIDs_RBSG b
	Left join Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse p
		on b.RowNo = p.RowNo
	Inner join Warehouse.iron.PrimaryRetailerIdentification i
		on b.PartnerID = i.PrimaryPartnerID
	Inner join Warehouse.Relational.[Partner] RBS_P
		on i.PartnerID = RBS_P.PartnerID
	Inner join #PartnerSettings ps
		on RBS_P.PartnerID = ps.partnerID
	Where 
		p.RowNo is null;
	
	-- Delete secondary partner records as not used for segmentation

	Delete from b
	From Warehouse.Staging.PartnerControlgroupIDs_RBSG b
	Left join warehouse.relational.[partner] p
		on p.partnerid = b.PartnerID
		and brandid is not null 
	Where
		p.partnerid is NULL;

	Delete from b
	From  Warehouse.Staging.PartnerControlgroupIDs_RBSG b
	Left join Warehouse.relational.ironoffercycles ioc
		on ioc.controlgroupid = b.RowNo
	Where
		ioc.controlgroupid is null;

	--Secial case - Hungry Horse 4th partner record:

	Delete from  Warehouse.Staging.PartnerControlgroupIDs_RBSG
	where partnerid = 4685;
	
	/******************************************************************************
	CHECK POINT: Check which segments are missing

	Create table for storing validation results

	Create table Warehouse.Staging.ControlSetup_Validation_RBS_Partners_To_Segment
		(ID INT IDENTITY (1,1)
		, PublisherType VARCHAR(50)
		, PartnerID INT
		, Segment VARCHAR(10)
		, RowNo INT
		, StartDate DATE
		, EndDate DATE
		, CONSTRAINT PK_ControlSetup_Validation_RBS_Partners_To_Segment PRIMARY KEY CLUSTERED (ID)  
		)
	******************************************************************************/

	-- Load errors

	Truncate table Warehouse.Staging.ControlSetup_Validation_RBS_Partners_To_Segment;

	Insert into Warehouse.Staging.ControlSetup_Validation_RBS_Partners_To_Segment
		(PublisherType
		, PartnerID
		, Segment
		, RowNo
		, StartDate
		, EndDate
		)
	Select
		'Warehouse' AS PublisherType
		, b.PartnerID
		, b.Segment
		, b.RowNo
		, b.StartDate
		, b.EndDate		
	From Warehouse.Staging.PartnerControlgroupIDs_RBSG b
	Left Join Warehouse.Staging.ControlSetup_PartnersToSeg_Warehouse p
		on b.RowNo = p.RowNo
	Where 
		p.RowNo is null;

END