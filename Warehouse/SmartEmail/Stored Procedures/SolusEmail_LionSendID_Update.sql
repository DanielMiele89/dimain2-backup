
-- =============================================
-- Author:		Rory
-- Create date:	2020-11-06
-- Description:	On the morning of a Solus email deployemnt, update the LionSendIDs of customers if they do / do not meet the criteria for a email group
-- =============================================

CREATE PROCEDURE [SmartEmail].[SolusEmail_LionSendID_Update] @SolusEmailDate DATE
AS
BEGIN

	SET NOCOUNT ON;
	
	--DECLARE @SolusEmailDate DATE = NULL
	DECLARE @LionSendID INT = 736

/*******************************************************************************************************************************************
	1.	If the current date is not a Solus email deployemnt given passed into @SolusEmailDate then exit
*******************************************************************************************************************************************/

	IF (SELECT CONVERT(DATE, GETDATE())) != @SolusEmailDate RETURN

/*******************************************************************************************************************************************
	2.	Fetch eligible customers
*******************************************************************************************************************************************/

/*First part of the code looks to get all the customer assigned to the relevent offers in both wave 1 and wave 2*/

   --First let us get the partner ids of the brands
IF OBJECT_ID('tempdb..#partners') IS NOT NULL DROP TABLE #partners;
  select PartnerID, PartnerName 
  into #partners
  from [Warehouse].[Relational].[Partner]
  where partnername in ('Harvey Nichols', 'Pandora', 'Clinique', 'Jimmy Choo');

 -- select * from  #partners;

   --Secondly using the partner ids, get the list of live offers ids for these at the 9th Feb 
  IF OBJECT_ID('tempdb..#ironofferids') IS NOT NULL DROP TABLE #ironofferids;
  select a.*, b.IronOfferID, b.IronOfferName, b.StartDate, b.EndDate
  into #ironofferids
  from #partners as a
  left join Relational.IronOffer as b 
	on a.PartnerID = b.PartnerID
  	and b.EndDate >=   '2021-02-09' and b.[StartDate] <=  '2021-02-11';

 --select * from #ironofferids order by 1,5;


IF OBJECT_ID('tempdb..#wave1members') IS NOT NULL DROP TABLE #wave1members;

	--Next, using the temp table of #ironofferids, find the customers eligible for the offer currently -what I am classifying as wave1
	select a.*, 
			c.IronOfferMemberID,
			c.CompositeID, 
			c.StartDate as Wave_1_OfferMemberStartDate, 
			c.EndDate as Wave_1_OfferMemberEndDate,
			c.ImportDate as Wave_1_OfferImportDate
	into #wave1members
	from #ironofferids as a
	inner join [Warehouse].[Relational].[IronOfferMember] as c
		on a.IronOfferID = c.IronOfferID
		AND C.StartDate = '2021-01-28 00:00:00.000' AND C.EndDate = '2021-02-10 23:59:59.000';
	
--select top 100 * from 	#wave1members;
	
	--Next, using the temp table of iron offer ids, find the customers eligible for the offer in the next wave 
IF OBJECT_ID('tempdb..#wave2members') IS NOT NULL DROP TABLE #wave2members;

	--Next, using the temp table of iron offer ids, find the customers eligible for the offer currently
	select a.*, 
			c.CompositeID, 
			c.StartDate as Wave_2_OfferMemberStartDate, 
			c.EndDate as Wave_2_OfferMemberEndDate,
			c.[Date] as Wave_2_OfferImportDate
	into #wave2members
	from #ironofferids as a
	inner join [Warehouse].[iron].[OfferMemberAddition] as c
		on a.IronOfferID = c.IronOfferID;



		/*
		select PartnerName, count(*) as vol from #wave1members group by PartnerName;
		select PartnerName, count(*) as vol from #wave2members group by PartnerName;
		*/
/*
--Having a look at how these temp tables have been created:
	EXEC tempdb.dbo.sp_help @objname = N'#wave1members';
	EXEC tempdb.dbo.sp_help @objname = N'#wave2members';
*/

--Was taking a long time to join data in next query so ensured adding index to speed this up which required NOT NULL columsn

CREATE INDEX CIX_CompPartner ON #wave1members (CompositeID, PartnerID)
CREATE INDEX CIX_CompPartner ON #wave2members (CompositeID, PartnerID)

--takes 2.5 mins, seem long....am I missing something?
IF OBJECT_ID('tempdb..#CustomerView') IS NOT NULL DROP TABLE #CustomerView;
	
		select  a.CompositeID, 
			count(distinct a.PartnerID) as Wave_1_Partners, 
			count(distinct b.PartnerID) as Wave_2_Partners
	into #CustomerView
	from #wave1members as a
	INNER join #wave2members as b
		on a.CompositeID = b.CompositeID 
		and a.PartnerID = b.PartnerID
	group by  a.CompositeID;

	
IF OBJECT_ID('tempdb..#eligible_offer_customers') IS NOT NULL DROP TABLE #eligible_offer_customers;
	--Table now has the customers who are eligible for the promotion as they have four offers for the brands in both waves. 
	select * 
	into #eligible_offer_customers
	from #CustomerView 
	where Wave_1_Partners = 4 and Wave_2_Partners = 4;
	
	CREATE INDEX CIX_CompPartner ON #CustomerView (CompositeID)


	/*Second part of the code looks to get all the information around the customer*/
	
	/*Let's first get the customers for this program which we want to contact*/
IF OBJECT_ID('tempdb..#Customer_Details') IS NOT NULL DROP TABLE #Customer_Details;

select  a.CompositeID, 
		a.FanID, 
		a.ClubID, 
		c.[Description], 
		d.social_class_desc, 
		case when CustomerSegment= 'V' then 'P' else 'C' end as Private_Core_Split,
		f.ProductHoldingGroupNumber, 
		f.ProductHoldingGroupName, 
		f.OperationalSegmentLabel, 
		f.OperationalSubSegmentID, 
		f.OperationalSubSegmentName 
into #customer_details
from
--The base of the currently active NWB population (ClubID = 132)
		(
	select fanid, 
		CompositeID, 
		clubid, 
		postcode 
		from Warehouse.Relational.Customer	cu
			where CurrentlyActive = 1 and clubid = 132
			and SourceUID NOT IN (SELECT SourceUID FROM Staging.Customer_DuplicateSourceUID)
			) as a
--Join to get their email marketing status
left join  Warehouse.Relational.Customer_MarketableByEmailStatus_MI as b
	on a.fanid = b.fanid
	and b.EndDate is null
--left join to get look up
LEFT JOIN warehouse.Relational.Customer_MarketableByEmailStatusTypes_MI AS C 
	ON B.MarketableID = C.ID	

--left join to get social stated
left join
(
select postcode, social_class, [description] as social_class_desc from Relational.CAMEO as a
left join Relational.CAMEO_CODE as b
	on a.cameo_code = b.cameo_code
left join Relational.CAMEO_SocialClassDescription as c
	on b.social_class = c.socialclass
) as d
	on a.postcode = d.postcode
left join [Warehouse].[Relational].[Customer_RBSGSegments] as e
	on a.fanid = e.FanID
	and e.enddate is NULL
left join  
	(
	select fanid, 
		ProductHoldingGroupNumber, 
		ProductHoldingGroupName, 
		OperationalSegmentLabel, 
		OperationalSubSegmentID, 
		OperationalSubSegmentName
from  Sandbox.Ewan.customerdefinitions 
	where  CycleID = (select max(cycleid) from Sandbox.Ewan.customerdefinitions)
	and IsActiveSchemeMember = 1
	) as f
	on a.fanid = f.FanID;
	
	
 
   --Assuming this is best eligible_customers of popluation before we look at offer eligibility  
  IF OBJECT_ID('tempdb..#eligible_customers') IS NOT NULL DROP TABLE #eligible_customers;
  select * 
  into #eligible_customers
  from #customer_details
	where [Description] = 'Marketable By Email' --Email Marketing
	AND		operationalsegmentlabel in ('B', 'C', 'D')
	AND		(
				(Private_Core_Split = 'P' 
						or 
				(social_class_desc in ('Higher & intermediate managerial, administrative, professional occupations', 
											'Supervisory, clerical & junior managerial, administrative, professional occupations'))))
											;


	/*Third part of the code looks to combine both the sligible offer and eligible customers and split into a T/C*/
	IF OBJECT_ID('tempdb..#pre_selection') IS NOT NULL DROP TABLE #pre_selection;
	select a.*
	into #pre_selection		
	from #eligible_customers as a
	left join 	#eligible_offer_customers as b		
	on a.compositeid = b.compositeid
	where b.compositeid is not NULL;



		--Create a generic sampling table for use, has ad id as primary key
IF OBJECT_ID('tempdb..#test1samplingtable') IS NOT NULL DROP TABLE #test1samplingtable;
CREATE TABLE #test1samplingtable
(
  randomid			int identity(1,1) primary key,
  fanid				int not null,
  testsplit  varchar(1) not null --Generic name for so can reuse code
);


--This is for the Prmier Test split 90/10 
INSERT INTO #test1samplingtable 
SELECT	 
		fanid,
		private_core_split
from #pre_selection where private_core_split = 'P';--Premier only


IF OBJECT_ID('tempdb..#test1control') IS NOT NULL DROP TABLE #test1control;
CREATE TABLE #test1control
( 
   randomid int primary key 
); 

DECLARE @controlvol int;
DECLARE @totalvol int; 


SET @totalvol = (select count(*) from #test1samplingtable );
SET @controlvol = (select(select count(*) from #test1samplingtable )*.1);--take 10% Control

WHILE (SELECT COUNT(*) FROM #test1control) <  @controlvol
BEGIN 
   BEGIN TRY  
      INSERT INTO #test1control
      SELECT CEILING(RAND(CHECKSUM(NEWID())) * @totalvol) 
   END TRY  
   BEGIN CATCH  
      PRINT 'discards duplicates' 
   END CATCH 
END 



--let do again for Core - so we know we have a max contact of 500k 
IF OBJECT_ID('tempdb..#test2samplingtable') IS NOT NULL DROP TABLE #test2samplingtable;
CREATE TABLE #test2samplingtable
(
  randomid			int identity(1,1) primary key,
  fanid				int not null,
  testsplit  varchar(1) not null --Generic name for so can reuse code
);


--This is for the Prmier Test split 90/10 
INSERT INTO #test2samplingtable 
SELECT	 
		fanid,
		private_core_split
from #pre_selection where private_core_split = 'C'--Premier only


IF OBJECT_ID('tempdb..#test2control') IS NOT NULL DROP TABLE #test2control;
CREATE TABLE #test2control
( 
   randomid int primary key
); 


DECLARE @controlvol2 int;
DECLARE @totalvol2 int; 


SET @totalvol2 = (select count(*) from #test2samplingtable);
SET @controlvol2 = (select count(*) from #test2samplingtable) - (select(500000 /*total selection vol*/ - (select (select count(*) from #test1samplingtable )*.9)))

--print @controlvol;



WHILE (SELECT COUNT(*) FROM #test2control) <  @controlvol2
BEGIN 
   BEGIN TRY  
      INSERT INTO #test2control
      SELECT CEILING(RAND(CHECKSUM(NEWID())) * @totalvol2)
   END TRY  
   BEGIN CATCH  
      PRINT 'discards duplicates' 
   END CATCH 
END 


IF OBJECT_ID('tempdb..#finalselection') IS NOT NULL DROP TABLE #finalselection;

select * 
into #finalselection
from
(
select fanid, testsplit, case when b.randomid is not NULL then 1 else 0 end as ControlFlag from #test1samplingtable as a
	left join #test1control as b
on a.randomid = b.randomid
union
select  fanid, testsplit, case when b.randomid is not NULL then 1 else 0 end as ControlFlag from #test2samplingtable as a
	left join #test2control as b
on a.randomid = b.randomid
) as a
;

--select testsplit, 
--		operationalsegmentlabel, 
--		sum(case when controlflag = 1 then 1 else 0 end) as Control_Vol,
--		sum(case when controlflag = 0 then 1 else 0 end) as Test_Vol, 
--		count(*) as total_vol,
--		count(distinct a.fanid) as Distinct_Vol
--	from #finalselection as a
--	left join #pre_selection as b
--	on a.fanid = b.FanID
--	group by testsplit, 
--operationalsegmentlabel;




----check all customers are against all these offers at source. --correct
--select count(*) as vol, count(distinct a.fanid),  (count(distinct a.fanid)*4) as test
--from #finalselection as a
--left join Warehouse.Relational.Customer as b
--	on a.fanid = b.FanID
--left join [Warehouse].[Relational].[IronOfferMember] as c
--	on b.CompositeID = c.CompositeID
--	and  C.StartDate = '2021-01-28 00:00:00.000' AND C.EndDate = '2021-02-10 23:59:59.000'
--where c.IronOfferID in (select IronOfferID from #ironofferids);


--select count(*) as vol, count(distinct a.fanid),  (count(distinct a.fanid)*4) as test
--from #finalselection as a
--left join Warehouse.Relational.Customer as b
--	on a.fanid = b.FanID
--left join  [Warehouse].[iron].[OfferMemberAddition] as c
--	on b.CompositeID = c.CompositeID
--where c.IronOfferID in (select IronOfferID from #ironofferids);

	
/*******************************************************************************************************************************************
	3.	Assign Control Group members
*******************************************************************************************************************************************/

	IF OBJECT_ID('[SmartEmail].[ValentinesDay]') IS NOT NULL DROP TABLE [SmartEmail].[ValentinesDay]
	SELECT	FanID
		,	TestSplit
		,	ControlFlag
	INTO [SmartEmail].[ValentinesDay]
	FROM #finalselection
	WHERE ControlFlag = 0

	IF OBJECT_ID('[SmartEmail].[ValentinesDay_ControlGroup]') IS NOT NULL DROP TABLE [SmartEmail].[ValentinesDay_ControlGroup]
	SELECT	FanID
		,	TestSplit
		,	ControlFlag
	INTO [SmartEmail].[ValentinesDay_ControlGroup]
	FROM #finalselection
	WHERE ControlFlag = 1
	
/*******************************************************************************************************************************************
	4.	Assign Solus customers
*******************************************************************************************************************************************/

	TRUNCATE TABLE [SmartEmail].[LionSend_CustomerOverride]
	INSERT INTO [SmartEmail].[LionSend_CustomerOverride]
	SELECT	FanID
		,	@LionSendID
	FROM [SmartEmail].[ValentinesDay]

END