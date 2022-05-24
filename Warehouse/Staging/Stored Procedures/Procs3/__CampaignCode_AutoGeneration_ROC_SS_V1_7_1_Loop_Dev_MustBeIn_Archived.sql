
CREATE PROCEDURE [Staging].[__CampaignCode_AutoGeneration_ROC_SS_V1_7_1_Loop_Dev_MustBeIn_Archived]
		(	@PartnerID CHAR(4),
			@StartDate DATE, 
			@EndDate DATE,
			@MarketableByEmail bit,
			@PaymentMethodsAvailable VARCHAR(10),
			@OfferID VARCHAR(40),
			@Throttling varchar(200),
			@ClientServicesRef VARCHAR(10),
			@OutputTableName VARCHAR (100),
			@CampaignName VARCHAR (250),
			@SelectionDate VARCHAR(11),
			@DeDupeAgainstCampaigns VARCHAR(50),
			@NotIn_TableName1 VARCHAR(100),
			@NotIn_TableName2 VARCHAR(100),
			@NotIn_TableName3 VARCHAR(100),
			@NotIn_TableName4 VARCHAR(100),
			@SelectedInAnotherCampaign VARCHAR(20),
			@CampaignTypeID CHAR(1),
			@CoreSpendersToPrime CHAR(1),
			@CustomerBaseOfferDate varchar(10)
)

AS
BEGIN
/****************************************************************************************************
Title: Auto-Generation Of Campaign Selection Code for ROC Launch or Welcome Offers
Author: Stuart Barnley
Creation Date: 31 Mar 2016
Purpose: Automatically create campaign offer selection code which can be run by Data Operations
-----------------------------------------------------------------------------------------------------
Modified Log:

Change No:	Name:			Date:			Description of change:
1.			Zoe Taylor		08/11/2016		* Moving start date clause from "Find OfferID's for previous 
											selection" to "Find Members from Previous Selection".
											
2.			Zoe Taylor		08/11/2016		* Added Row_Number to "Build Initial Selections Table"
											so the delete statemtent for throttling works correctly.
											
3.			Zoe Taylor		09/11/2016		* Change the table name "#Selection" to "#Selections"
											in "Find Campaign Spenders and Force back In"

4.			Zoe Taylor		09/11/2016		* Added Zoe Taylor and Ajith Asokan to the username 
											parameter

5.			Stuart Barnley  30/12/2016		* Amendment to no longer use Campaign_history as no 
											  longer being updated due to new reporting requirments
											
****************************************************************************************************/

DECLARE @SQLCode nvarchar(MAX),@UserName Varchar(50)
SET @UserName = (SELECT CASE	WHEN USER_NAME() = 'Suraj' THEN 'Suraj Chahal'
				WHEN SYSTEM_USER = 'Stuart' THEN 'Stuart Barnley'
				WHEN USER_NAME() = 'Glen' THEN 'Glen Ihama'
				WHEN USER_NAME() = 'Ijaz' THEN 'Ijaz Amjad'
				WHEN USER_NAME() = 'Zoe' THEN 'Zoe Taylor'
				WHEN USER_NAME() = 'Ajith' THEN 'Ajith Asokan'
				ELSE SYSTEM_USER
			END)

DECLARE @Dedupe BIT, @Offer1 int,@Offer2 int,@Offer3 int,@Offer4 int,@Offer5 int,@Offer6 int,@ShopperSegments varchar(15),
		@EndDateTime Datetime

Set @EndDateTime = Dateadd(ss,-1,Cast(Dateadd(day,1,@EndDate) as datetime))

Set @Dedupe = 1

Set @Offer1 = Cast(Left(@OfferID,5) as int)
Set @Offer2 = Cast(Right(Left(@OfferID,11),5) as int)
Set @Offer3 = Cast(Right(Left(@OfferID,17),5) as int)
Set @Offer4 = Cast(Right(Left(@OfferID,23),5) as int)
Set @Offer5 = Cast(Right(Left(@OfferID,29),5) as int)
Set @Offer6 = Cast(Right(@OfferID,5) as int)


--Select @Offer1,@Offer2,@Offer3,@Offer4,@Offer5,@Offer6
Set @ShopperSegments = 
	(Select	Case 
				When @Offer1 > 0 Then '1,' Else '' 
			End+
			Case
				When @Offer2 > 0 Then '2,' Else ''
			End+
			Case
				When @Offer3 > 0 Then '3,' Else '' 
			End+
			Case
				When @Offer4 > 0 Then '4,' Else ''
			End+
			Case
				When @Offer5 > 0 Then '5,' Else '' 
			End+
			Case
				When @Offer6 > 0 Then '6,' Else '' 
			End
	)
Set @ShopperSegments = Left(@ShopperSegments,Len(@ShopperSegments)-1)

--Select @ShopperSegments
--------------------------------------------------------------------------------
-------------Create table that holds a list of Throttling Amounts---------------
--------------------------------------------------------------------------------
Declare @Segment tinyint

Set @Segment = 1

--Select @Throttling as t into #t1

Create Table #Throttling (Limit varchar(20), LimitInCtrl int, SegmentID tinyint)


DECLARE @Limit INT
WHILE (CHARINDEX(',', @Throttling, 0) > 0)
        BEGIN
              SET @Limit =   CHARINDEX(',',    @Throttling, 0)     
			  INSERT INTO   #Throttling (Limit,LimitInCtrl,SegmentID)
              --LTRIM and RTRIM to ensure blank spaces are   removed
              SELECT RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) ,
					 RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) ,
					 @Segment 
              SET @Throttling = STUFF(@Throttling,   1, @Limit,   '') 
			  Set @Segment = @Segment+1
        END

		INSERT INTO   #Throttling (Limit,LimitInCtrl,SegmentID)
        SELECT RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) ,
			   RTRIM(LTRIM(SUBSTRING(@Throttling,   0, @Limit))) ,
			   @Segment 

	--	Select * from #Throttling

--------------------------------------------------------------------------------
----------Create table that holds a list of OfferIDs per Headroom Segment-------
--------------------------------------------------------------------------------

SET @SQLCode = ''

SET @SQLCode = @SQLCode+

'
/*******************************************************
Campaign: '+ @ClientServicesRef + ' - '+ @CampaignName + '
Selection Date: '+ @SelectionDate + '
Executed by: '+ @UserName + '
Output Table Name: '+ @OutputTableName + '
*******************************************************/'
+
CASE
	WHEN  LEN(@SelectedInAnotherCampaign) > 0 THEN '
IF OBJECT_ID ('+CHAR(39)+'tempdb..#MustBeIn'+CHAR(39)+') IS NOT NULL DROP TABLE #MustBeIn
SELECT	DISTINCT 
	ch.CompositeID
INTO #MustBeIn
FROM Warehouse.Relational.IronOffer_Campaign_HTM htm
INNER JOIN Warehouse.Relational.IronOfferMember ch
	ON htm.IronOfferID = ch.IronOfferID 
WHERE	htm.ClientServicesRef in ('''+REPLACE(@SelectedInAnotherCampaign,',',CHAR(39)+','+CHAR(39))+''')

Create Clustered index i_MustBeIn_CompositeID on #MustBeIn (CompositeID)
'	ELSE ''
END+ '


/****************************************************************************
***********************Find live OfferIDs with members***********************
****************************************************************************/

SELECT	DISTINCT 
			CompositeID
		into #cha
		FROM Warehouse.Relational.IronOfferMember cha (NOLOCK)
		LEFT OUTER JOIN Warehouse.Relational.Partner_NonCoreBaseOffer ncb
			ON cha.IronOfferID = ncb.IronOfferID
		inner join warehouse.relational.IronOffer_Campaign_HTM as h
			on cha.IronOfferID = h.IronOfferID
		WHERE	h.PartnerID = ' + @PartnerID + '
			AND cha.EndDate >= Cast('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+ ' as date)
			AND ncb.IronOfferID IS NULL
'+
Case
	When @CustomerBaseOfferDate <> '' then '
/****************************************************************************
*********************Find OfferIDs for previous selection********************
****************************************************************************/
IF OBJECT_ID (''tempdb..#Offers'') IS NOT NULL DROP TABLE #Offers
Select Distinct i.IronOfferID
Into #Offers
From Warehouse.relational.IronOffer as i
inner join Warehouse.Relational.IronOffer_Campaign_HTM as htm
	on i.IronOfferID = htm.IronOfferID
Where	htm.ClientServicesRef = '''+@ClientServicesRef+'''
 
/****************************************************************************
*********************Find Members from previous selection********************
****************************************************************************/

IF OBJECT_ID (''tempdb..#Members'') IS NOT NULL DROP TABLE #Members
Select	ch.CompositeID
Into #Members
From Warehouse.Relational.IronOfferMember as ch
inner join #Offers as o
	on ch.IronOfferID = o.IronOfferID
Where  ch.StartDate = '''+@CustomerBaseOfferDate+'''

Create clustered index i_Members_CompositeID on #Members (CompositeID)						
'
	Else ''					
End
+'
/****************************************************************************
*********************Get Basic Customer Info for Members*********************
****************************************************************************/

Select	c.FanID,
		c.CompositeID,
		c.MarketableByEmail,
		''Mail'' as GRP
Into #Customers
From Warehouse.Relational.Customer as c'+
Case
	When @CustomerBaseOfferDate <> '' then '
inner join #Members as m
	on c.CompositeID = m.CompositeID'
	Else ''
End +

CASE
	WHEN  LEN(@SelectedInAnotherCampaign) > 0 THEN '
inner join #MustBeIn as mbi
	on c.CompositeID = mbi.CompositeID'
	Else ''
End + '
Where	CurrentlyActive = 1'+
		Case
			When @MarketableByEmail = 1 then '
		and	MarketableByEmail = 1 
		and	LEN(c.PostCode) >= 3'
			Else ''
		End+'

/****************************************************************************
*****************Building the Marketable by Email Customer Base**************
****************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#CustBase'+char(39)+') IS NOT NULL DROP TABLE #CustBase
SELECT	DISTINCT
	c.FanID,
	c.CompositeID, 
	c.MarketableByEmail,
	NULL as HTMID,
	NULL as HTM_Description,
	ss.ShopperSegmentTypeID as ShopperSegmentID,
	c.Grp
INTO #CustBase
FROM #Customers c
INNER JOIN Warehouse.Segmentation.ROC_Shopper_Segment_Members as ss
	ON c.FanID = ss.FanID
	AND ss.ShopperSegmentTypeID IN ('+@ShopperSegments+')
	AND ss.EndDate IS NULL
	AND ss.PartnerID = '+CAST(@PartnerID AS VARCHAR(5))+
Case
			When @MarketableByEmail = 1 then '
INNER JOIN Warehouse.Relational.CustomerPaymentMethodsAvailable cpm
	ON c.FanID = cpm.FanID
	AND cpm.EndDate IS NULL
	AND cpm.PaymentMethodsAvailableID IN ('+@PaymentMethodsAvailable+')
LEFT OUTER JOIN Warehouse.Relational.Customers_ReducedFrequency_CurrentExclusions ce
      ON c.FanID = ce.FanID
LEFT OUTER JOIN Warehouse.Relational.SmartFocusUnSubscribes un
	ON c.FanID = un.FanID
	AND un.EndDate IS NULL'
		   Else ''
End	+'
LEFT OUTER JOIN #cha as cha
	ON c.CompositeID = cha.CompositeID'
+
CASE	WHEN @DeDupeAgainstCampaigns <> ''
	THEN '
LEFT OUTER JOIN (
		SELECT	DISTINCT 
			ch.IronOfferMember
		FROM Warehouse.Relational.IronOffer_Campaign_HTM htm
		INNER JOIN Warehouse.Relational.IronOfferMember ch
			ON htm.IronOfferID = ch.IronOfferID 
		WHERE	htm.ClientServicesRef IN ('+Char(39)+Replace(@DeDupeAgainstCampaigns,',',''',''')+Char(39)+')
		)ioh
	ON c.CompositeID = ioh.CompositeID'
	ELSE ''
END+
'
WHERE	c.FanID is not null'+
	CASE
		WHEN @DeDupeAgainstCampaigns <> '' THEN '
		AND ioh.CompositeID IS NULL'
		ELSE ''
	END+	
	CASE
		WHEN @NotIn_TableName1 <> '' THEN '
		AND c.FanID IN (SELECT DISTINCT FanID FROM '+@NotIn_TableName1+')'
		ELSE ''
	END+
	CASE
		WHEN @NotIn_TableName2 <> '' THEN '
		AND c.FanID NOT IN (SELECT DISTINCT FanID FROM '+@NotIn_TableName2+')'
		ELSE ''
	END+
	CASE
		WHEN @NotIn_TableName3 <> '' THEN '
		AND c.FanID NOT IN (SELECT DISTINCT FanID FROM '+@NotIn_TableName3+')'
		ELSE ''
	END+
	CASE
		WHEN @NotIn_TableName4 <> '' THEN '
		AND c.FanID NOT IN (SELECT DISTINCT FanID FROM '+@NotIn_TableName4+')'
		ELSE ''
	END+
	Case
		When @MarketableByEmail = 1 then '
		AND CPM.FanID is not null
		And CE.FanID is null
		AND UN.FanID is null
		AND CHA.CompositeID is null
		'
	Else ''
	End+'
--**
CREATE CLUSTERED INDEX IDX_Fan ON #CustBase (FanID)

'+
'
/************************************************************************
************Build Initial Selections Table, Adding Offer Codes***********
************************************************************************/
IF OBJECT_ID ('+CHAR(39)+'tempdb..#Selections'+CHAR(39)+') IS NOT NULL DROP TABLE #Selections
Select	*'
		+ Case
				When (Select Sum(LimitInCtrl) From #Throttling as t) > 0 then ',ROW_NUMBER() OVER(PARTITION BY OfferID ORDER BY NewID() DESC) AS Row_Num'
				Else ''
		  End +'
INTO #Selections
From (
Select c.FanID,
	c.CompositeID,
	c.MarketableByEmail,
	c.HTMID,
	c.HTM_Description,
	ShopperSegmentID as [ShopperSegmentTypeID],
	p.PartnerID,
	PartnerName,
	CASE
		WHEN ShopperSegmentID = 1 THEN '+CAST(@Offer1 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 2 THEN '+CAST(@Offer2 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 3 THEN '+CAST(@Offer3 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 4 THEN '+CAST(@Offer4 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 5 THEN '+CAST(@Offer5 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 6 THEN '+CAST(@Offer6 AS VARCHAR(5))+'
	END as OfferID,
	'+
	+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
	CAST('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+' AS DATE) as StartDate,
	CAST('+ CHAR(39) + convert(varchar, @EndDateTime, 25) + CHAR(39)+' AS DATETime) as EndDate,
	'+char(39)+'E'+char(39)+' as [Comm Type],
	CAST(NULL AS VARCHAR(5)) as TriggerBatch,
	Grp
FROM #CustBase c
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = '+ @PartnerID
+
') as a
'+
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 1) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 1) as varchar(10))+ ' and ShopperSegmentTypeID = 1
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 2) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 2) as varchar(10))+ ' and ShopperSegmentTypeID = 2
'	Else '' 
End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 3) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 3) as varchar(10))+ ' and ShopperSegmentTypeID = 3
'	Else '' 
End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 4) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 4) as varchar(10))+ ' and ShopperSegmentTypeID = 4
'	Else '' 
End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 5) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 5) as varchar(10))+ ' and ShopperSegmentTypeID = 5
'	Else '' 
End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 6) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 6) as varchar(10))+ ' and ShopperSegmentTypeID = 6
'	Else '' 
End +

Case
	When (Select Sum(LimitInCtrl) From #Throttling as t) > 0 then '
Alter Table #Selections Drop Column Row_Num'
	Else ''
End+
'
--SELECT	OfferID,
--		ShopperSegmentTypeID,
--		COUNT(1)
--FROM #Selections
--GROUP BY OfferID,
--		 ShopperSegmentTypeID
--ORDER BY OfferID

'+ Case
		When @CoreSpendersToPrime = '1' then '
/*************************************************************************
****************Find Campaign Spenders and Force back In******************
*************************************************************************/
Select IronOfferID 
Into #OffersPast
From Warehouse.Relational.IronOffer_Campaign_HTM as a
Where ClientServicesRef = '''+@ClientServicesRef+'''

Select Distinct pt.FanID
Into #Spenders
From #OffersPast as o
inner join Warehouse.Relational.PartnerTrans as pt
	on	o.IronOfferID = pt.IronOfferID
Where	Cast(pt.Cashbackearned as real) / TransactionAmount >= 0.0141 and
		pt.TransactionAmount > 0

Insert into #Selections
Select	c.FanID,
		c.CompositeID,
		c.MarketableByEmail,
		NULL as HTMID,
		NULL as HTM_Description,
		ss.ShopperSegmentTypeID,
		p.PartnerID,
		p.PartnerName,
		CASE
			WHEN ss.ShopperSegmentTypeID = 3 THEN '+CAST(@Offer4 AS VARCHAR(5))+'
			WHEN ss.ShopperSegmentTypeID = 5 THEN '+CAST(@Offer6 AS VARCHAR(5))+'
		END as OfferID,
		'+
	+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
		CAST('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+' AS DATE) as StartDate,
		CAST('+ CHAR(39) + convert(varchar, @EndDateTime, 25) + CHAR(39)+' AS DATETime) as EndDate,
		'+char(39)+'E'+char(39)+' as [Comm Type],
		CAST(NULL AS VARCHAR(5)) as TriggerBatch,
		''Mail'' as Grp
From #Spenders as s
inner join Warehouse.relational.Customer as c
	on s.FanID = c.FanID
inner join warehouse.relational.partner as p
	on p.PartnerID = '+CAST(@PartnerID AS VARCHAR(5))+'
INNER JOIN Warehouse.Segmentation.ROC_Shopper_Segment_Members as ss
	ON c.FanID = ss.FanID
	AND ss.ShopperSegmentTypeID NOT IN ('+@ShopperSegments+',1,2)
	AND ss.EndDate IS NULL
	AND ss.PartnerID = '+CAST(@PartnerID AS VARCHAR(5))+'
Left Outer join #Selections as f
	on s.FanID = f.FanID
Where f.FanID is null'
		Else ''
	End +'

/*************************************************************************
***********Adding a new Row Number from which we can chunk size***********
*************************************************************************/

IF OBJECT_ID (''tempdb..#FinalSelection'') IS NOT NULL DROP TABLE #FinalSelection
SELECT	ROW_NUMBER() over(order by FanID) as  SelectionID,
	*
INTO #FinalSelection
FROM #Selections
--**

/*************************************************************************
**************Build the final selection table Infrastructure**************
*************************************************************************/
CREATE TABLE ' +@OutputTableName+ '
		(
		[FanID] [int] NOT NULL PRIMARY KEY,
		[CompositeID] [bigint] NULL,
		[MarketablebyEmail] [bit] NULL,
		[HTMID] [int] NULL,
		[HTM_Description] [varchar](50) NULL,
		[ShopperSegmentTypeID] int null,
		[PartnerID] [int] NOT NULL,
		[PartnerName] [varchar](100) NOT NULL,
		[OfferID] [int] NULL,
		[ClientServicesRef] [varchar](10) NOT NULL,
		[StartDate] [datetime] NULL,
		[EndDate] [datetime] NULL,
		[Comm Type] [varchar](1) NOT NULL,
		[TriggerBatch] [int] NULL,
		[Grp] [varchar](7) NOT NULL,
		)

/**********************************************************************************************
*************************Insert Targetted Offers to Selection Table****************************
**********************************************************************************************/
--SELECT	COUNT(1)
--FROM #FinalSelection
--**

/***************************************************************************
***************************Declare the variables****************************
***************************************************************************/
DECLARE @StartRow INT,
	@ChunkSize INT
SET @StartRow = 0
SET @ChunkSize = 500000

/********************************************************
*************************Insert**************************
********************************************************/
WHILE EXISTS (SELECT 1 FROM #FinalSelection WHERE SelectionID > @StartRow)
BEGIN
---------------------------------------------
INSERT INTO ' +@OutputTableName+ '
SELECT	TOP	
	(@ChunkSize)
	FanID,
	CompositeID,
	MarketableByEmail,
	HTMID,
	HTM_Description,
	ShopperSegmentTypeID,
	PartnerID,
	PartnerName,
	OfferID,
	ClientServicesRef,
	StartDate,
	EndDate,
	[Comm Type],
	TriggerBatch,
	Grp
FROM #FinalSelection
WHERE SelectionID > @StartRow
ORDER BY SelectionID

SET @StartRow = (SELECT COUNT(1) FROM '+ @OutputTableName +')

END


/************************************************************************
*******************************Testing***********************************
************************************************************************/
--**Check Count is Distinct
--SELECT	COUNT(1),
--	COUNT(DISTINCT FanID) 
--FROM '+ @OutputTableName + '
----**


/************************************************************************
***********************Stats for Email and Brief*************************
************************************************************************/
--**Offer Split
--SELECT	OfferID,
--	CashbackRate,
--	SUM(CASE WHEN s.Grp = '+char(39)+'Mail'+char(39)+' THEN 1 ELSE 0 END) as MailedCustomers,
--	SUM(CASE WHEN s.Grp = '+char(39)+'Control'+char(39)+' THEN 1 ELSE 0 END) as ControlCustomers,
--	CommissionRate
--FROM '+ @OutputTableName + ' s
--LEFT OUTER JOIN		(
--			SELECT	RequiredIronOfferID,
--				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END)/100 as CashbackRate,
--				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
--			FROM slc_report.dbo.PartnerCommissionRule p
--			WHERE RequiredIronOfferID IS NOT NULL
--			GROUP BY RequiredIronOfferID
--			) pcr
--	ON s.OfferID = pcr.RequiredIronOfferID
--GROUP BY OfferID, CashbackRate, CommissionRate
--ORDER BY OfferID

/****************************************************************************
*********************Building the OOP Control Customer Base******************
****************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#CustBaseCtrl'+char(39)+') IS NOT NULL DROP TABLE #CustBaseCtrl
SELECT	DISTINCT
	ss.FanID,
	NULL as CompositeID, 
	0 as MarketableByEmail,
	NULL as HTMID,
	NULL as HTM_Description,
	ss.[ShopperSegmentTypeID],
	p.PartnerID,
	p.PartnerName,
	CASE
		WHEN ss.ShopperSegmentTypeID = 1 THEN '+CAST(@Offer1 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 2 THEN '+CAST(@Offer2 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 3 THEN '+CAST(@Offer3 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 4 THEN '+CAST(@Offer4 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 5 THEN '+CAST(@Offer5 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 6 THEN '+CAST(@Offer6 AS VARCHAR(5))+'
	END as OfferID,
	'+
	+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
	CAST('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+' AS DATE) as StartDate,
	CAST('+ CHAR(39) + convert(varchar, @EndDateTime, 25) + CHAR(39)+' AS DATETime) as EndDate,
	'+char(39)+'E'+char(39)+' as [Comm Type],
	CAST(NULL AS VARCHAR(5)) as TriggerBatch,
	''Control'' as Grp
INTO #CustBaseCtrl
FROM Warehouse.[Segmentation].[Roc_Shopper_Segment_Members_Control] as ss
Left Outer Join Warehouse.Staging.Customer as c
	on	ss.FanID = c.FanID
inner join warehouse.relational.partner as p
	on	p.PartnerID = '+CAST(@PartnerID AS VARCHAR(5))+'
Where	ss.EndDate IS NULL
		AND ss.ShopperSegmentTypeID IN ('+@ShopperSegments+')
		AND ss.PartnerID = '+CAST(@PartnerID AS VARCHAR(5))+'
		AND c.FanID is null
/****************************************************************************
**********************View Ctrl Group Offer Counts***************************
****************************************************************************/
--Select	OfferID,
--		ShopperSegmentTypeID,
--		Count(*) as Customers
--From #CustBaseCtrl
--Group by OfferID,
--		 ShopperSegmentTypeID

/****************************************************************************
******************************Write to Sandbox*******************************
****************************************************************************/
Select *
Into ' +@OutputTableName+ '_OOP_Ctrl 
From #CustBaseCtrl

/****************************************************************
*******Add new campaign to NominatedOfferMember_TableNames*******
****************************************************************/
INSERT INTO Warehouse.Relational.NominatedOfferMember_TableNames
SELECT	'''+ @OutputTableName + ''' as TableName

--SELECT	*
--FROM Warehouse.Relational.NominatedOfferMember_TableNames
--ORDER BY TableID


/********************************************************
**********Add new campaign to CBP_CampaignNames**********
********************************************************/

'+Case
		When @CustomerBaseOfferDate = '' then 
'
--**Load CSRef and CampaignName into temp table
IF OBJECT_ID ('+char(39)+'tempdb..#CampaignName'+char(39)+') IS NOT NULL DROP TABLE #CampaignName
SELECT	DISTINCT ClientServicesRef,
	'+char(39)+@CampaignName+char(39)+' as CampaignName
INTO #CampaignName
FROM '+ @OutputTableName + '

--**Load into live table where combination has not been seen before
INSERT INTO Warehouse.Relational.CBP_CampaignNames
SELECT	cn.ClientServicesRef,
	cn.CampaignName
FROM #CampaignName cn
LEFT OUTER JOIN Warehouse.Relational.CBP_CampaignNames cbp
	ON cbp.ClientServicesRef = cn.ClientServicesRef
	AND cbp.CampaignName = cn.CampaignName
WHERE	cbp.ClientServicesRef IS NULL
	OR cbp.CampaignName IS NULL
--**
'
		Else ''
	End+'
--SELECT	* 
--FROM Warehouse.Relational.CBP_CampaignNames
--WHERE ClientServicesRef = '''+ @ClientServicesRef + '''


/************************************************************
***********Add new campaign to IronOffer_Campaign_Type*******
************************************************************/
'+Case
		When @CustomerBaseOfferDate = '' then 
'
--SELECT	ID,
--	ClientServicesRef,
--	CampaignTypeID,
--	IsTrigger,
--	ControlPercentage
--FROM Warehouse.Staging.IronOffer_Campaign_Type
--WHERE ClientServicesRef = '''+ @ClientServicesRef + '''


INSERT INTO Warehouse.Staging.IronOffer_Campaign_Type
SELECT	DISTINCT ClientServicesRef,
	'+@CampaignTypeID+' as CampaignTypeID, 
	0 as IsTrigger,
	0 as ControlPercentage
FROM '+ @OutputTableName + '
WHERE	ClientServicesRef NOT IN (SELECT DISTINCT ClientServicesRef FROM Warehouse.Staging.IronOffer_Campaign_Type)
--**
'
	Else ''
End +'
----SELECT	*
----FROM Warehouse.Staging.IronOffer_Campaign_Type
----WHERE ClientServicesRef = '''+ @ClientServicesRef + '''

Insert into Warehouse.Relational.IronOffer_ROCOffers
SELECT Distinct OfferID
FROM '+ @OutputTableName+'
Where OfferID not in (Select IronOfferID From Warehouse.Relational.IronOffer_ROCOffers)'


--select @SQLCode
exec sys.sp_executesql @SQLCode

END