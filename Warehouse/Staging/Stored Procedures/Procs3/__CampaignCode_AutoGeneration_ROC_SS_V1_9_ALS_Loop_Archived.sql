
CREATE PROCEDURE [Staging].[__CampaignCode_AutoGeneration_ROC_SS_V1_9_ALS_Loop_Archived]
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
			-- ********************** Amendment Start (ZT '2017-03-02') ********************** 
			@MustBeIn_TableName1  VARCHAR(100),
			@MustBeIn_TableName2  VARCHAR(100),
			@MustBeIn_TableName3  VARCHAR(100),
			@MustBeIn_TableName4  VARCHAR(100),
			@Gender CHAR(1),
			@AgeRange VARCHAR(7),
			@CampaignID_Include CHAR(3),
			@CampaignID_Exclude CHAR(3),
			@DriveTimeMins CHAR(3),
			@LiveNearAnyStore BIT,
			@OutletSector CHAR(6), 
			@SocialClass VARCHAR(5),
			-- *********************** Amendment End  (ZT '2017-03-02') ********************** 
			@SelectedInAnotherCampaign VARCHAR(20),
			@CampaignTypeID CHAR(1),
			@CustomerBaseOfferDate varchar(10),
			@RandomThrottle bit
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

*****************************************************************************************************
ALS Updates:

6.			Zoe Taylor		16/10/2017		* Changed ROW_NUMBER to use NewID or Ranking depending 
											on the parameter value
											
****************************************************************************************************/

DECLARE @SQLCode nvarchar(MAX) ,@UserName Varchar(50)

SET @UserName = (SELECT CASE	WHEN USER_NAME() = 'Suraj' THEN 'Suraj Chahal'
				WHEN SYSTEM_USER = 'Stuart' THEN 'Stuart Barnley'
				WHEN USER_NAME() = 'Glen' THEN 'Glen Ihama'
				WHEN USER_NAME() = 'Ijaz' THEN 'Ijaz Amjad'
				WHEN USER_NAME() = 'Zoe' THEN 'Zoe Taylor'
				WHEN USER_NAME() = 'Ajith' THEN 'Ajith Asokan'
				ELSE SYSTEM_USER
			END)

DECLARE @Dedupe BIT, 
		@Offer1 int,
		@Offer2 int,
		@Offer3 int,
		@Offer4 int,
		@Offer5 int,
		@Offer6 int,
		@ShopperSegments varchar(15),
		@EndDateTime Datetime,
		@homemoverdate date, 
		@birthdaystart date,
		@birthdayend date, 
		@activateddate date

Set @ActivatedDate = dateadd(day,-28,cast(getdate() as date))
Set @HomemoverDate = dateadd(day,-28,cast(getdate() as date))
SET @BirthdayStart = DATEADD(YEAR,-(DATEPART(YEAR,@StartDate)-1900),@StartDate)
SET @BirthdayEnd = DATEADD(YEAR,-(DATEPART(YEAR,@EndDate)-1900),@EndDate)
If @BirthdayEnd < @BirthdayStart Set @BirthdayEnd = DATEADD(YEAR, 1, DATEADD(YEAR,-(DATEPART(YEAR,cast(@EndDate as date))-1900),cast(@EndDate as date)))
Set @EndDateTime = Dateadd(ss,-1,Cast(Dateadd(day,1,@EndDate) as datetime))
Set @Dedupe = 1


--DECLARE @OfferID varchar(40) = '12310,12311,12312,00000,00000,00000', 
--		@Offer1 int,
--		@Offer2 int,
--		@Offer3 int,
--		@Offer4 int,
--		@Offer5 int,
--		@Offer6 int

-- Shopper Segment Offers
Set @Offer1 = Cast(Left(@OfferID,5) as int)				-- Acquire
Set @Offer2 = Cast(Right(Left(@OfferID,11),5) as int)	-- Lapsed
Set @Offer3 = Cast(Right(Left(@OfferID,17),5) as int)	-- Shopper
-- Birthday/Homemover/Welcome offers
Set @Offer4 = Cast(Right(Left(@OfferID,23),5) as int)	-- Welcome
Set @Offer5 = Cast(Right(Left(@OfferID,29),5) as int)	-- Birthday
Set @Offer6 = Cast(Right(@OfferID,5) as int)			-- Homemover

--select @offer4, @offer5, @offer6

Set @ShopperSegments = 
	(Select	Case 
				When @Offer1 > 0 Then '7,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 7 - acquire  *****
			End+
			Case
				When @Offer2 > 0 Then '8,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 8 - lapsed  *****
			End+
			Case
				When @Offer3 > 0 Then '9,' Else '' -- ***** Comment by ZT '2017-03-15': changed to segment 9 - shopper  *****
			End	+
			-- ***** Comment by ZT '2017-04-26': Assigned 'fake' segments to control throttling for welcome, bday, hmover  *****
			Case
				When @Offer4 > 0 Then '10,' Else '' -- ***** Comment by ZT '2017-04-26': welcome  *****
			End +
			Case
				When @Offer5 > 0 Then '11,' Else '' -- ***** Comment by ZT '2017-04-26': bday  *****
			End+
			Case
				When @Offer6 > 0 Then '12,' Else '' -- ***** Comment by ZT '2017-04-26': homemover  *****
			End

	)

Set @ShopperSegments = Left(@ShopperSegments,Len(@ShopperSegments)-1)

--------------------------------------------------------------------------------
-------------Create table that holds a list of Throttling Amounts---------------
--------------------------------------------------------------------------------
Declare @Segment tinyint

Set @Segment = 7

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
CASE	WHEN @CampaignID_Include <> ''
	THEN '
EXEC Warehouse.Staging.Partner_GenerateTriggerMember '+@CampaignID_Include
	ELSE ''
END
+'
'+
CASE	WHEN @CampaignID_Exclude <> ''
	THEN '
EXEC Warehouse.Staging.Partner_GenerateTriggerMember '+@CampaignID_Exclude
	ELSE ''
END
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
+
CASE
	WHEN @LiveNearAnyStore = 1 AND @DriveTimeMins <> '' THEN '

/*************************************************
************Finding Partner PostalSecors**********
*************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#PostalSectors'+char(39)+') IS NOT NULL DROP TABLE #PostalSectors
SELECT	DISTINCT
	o.PostalSector
INTO #PostalSectors
FROM Warehouse.Relational.Outlet o
INNER JOIN SLC_Report.dbo.RetailOutlet ro
	ON o.OutletID = ro.ID
	AND ro.SuppressFromSearch = 0
WHERE o.PartnerID = '+@PartnerID +' 
--**
/***************************************************************************
********Finding customers living within Drivetime from Partner Outlet*******
***************************************************************************/

IF OBJECT_ID ('+char(39)+'tempdb..#CustsInRange'+char(39)+') IS NOT NULL DROP TABLE #CustsInRange
SELECT	* 
INTO #CustsInRange
FROM	(
	SELECT	ROW_NUMBER() OVER(PARTITION BY FanID order by DriveTimeMins ASC) as RowNo,
		FanID,
		cb.PostalSector,
		ps.PostalSector as OutletPostalSector,
		DriveTimeMins
	FROM Warehouse.Relational.Customer cb
	INNER JOIN Warehouse.Relational.DriveTimeMatrix dtm
		ON cb.PostalSector = dtm.FromSector
	INNER JOIN #PostalSectors ps
		ON dtm.ToSector = ps.PostalSector
		AND dtm.DriveTimeMins <= '+@DriveTimeMins +'
	) a
WHERE RowNo = 1
--**
CREATE CLUSTERED INDEX IDX_FanID ON #CustsInRange (FanID)

'
	ELSE ''
END+

'
/****************************************************************************
********************************Create Customer Table************************
****************************************************************************/

Select	Distinct 
		c.FanID, 
		c.CompositeID, 
		c.MarketableByEmail,
		c.Postcode,
		c.dob,
		c.AgeCurrent,
		c.Gender,
		cr.Ranking,
		c.ActivatedDate,
		Case
			When h.FanID is null then 0
			Else 1
		End as Homemover
Into #CustomerBase
From Warehouse.relational.Customer as c
inner join Segmentation.Roc_Shopper_Segment_CustomerRanking cr
		on cr.PartnerID = ' +@PartnerID+ '
		and cr.FanID = c.FanID
left join Warehouse.Relational.Homemover_Details h
		on c.FanId = h.FanID
		and h.LoadDate >= '''+ cast(@HomemoverDate as varchar(20))+''''+'
LEFT OUTER JOIN #cha as cha
	ON c.CompositeID = cha.CompositeID'
+
	CASE WHEN @CampaignID_Include <> '' THEN'
INNER JOIN Warehouse.Relational.PartnerTrigger_Members AS ptm
	ON c.FanID = ptm.FanID
	AND ptm.CampaignID = '+ @CampaignID_Include
	ELSE ''
END+
CASE	WHEN @CampaignID_Exclude <> ''
	THEN '
LEFT OUTER JOIN Warehouse.Relational.PartnerTrigger_Members AS ptm2
	ON c.FanID = ptm2.FanID
	AND ptm2.CampaignID = '+ @CampaignID_Exclude
	ELSE ''
END+'
LEFT OUTER JOIN Warehouse.Relational.cameo ca
	on ca.Postcode = c.PostCode
LEFT OUTER JOIN Relational.CAMEO_CODE cc
	on cc.CAMEO_CODE = ca.CAMEO_CODE'
	+
CASE
		WHEN  LEN(@SelectedInAnotherCampaign) > 0 THEN '
	inner join #MustBeIn as mbi
		on c.CompositeID = mbi.CompositeID'
		Else ''
End + 
CASE
	WHEN @LiveNearAnyStore = 1 AND @DriveTimeMins <> '' THEN '
	inner join #CustsInRange as cir
		on c.FanID = cir.FanID'
Else ''
End + '
Where	cha.CompositeID is null'+
Case
		When @MarketableByEmail = 1 then '
		and MarketableByEmail = 1 
		and	LEN(c.PostCode) >= 3'
		Else ''
End
+
	CASE
		WHEN @CampaignID_Exclude <> '' THEN '
	AND ptm2.FanID IS NULL'
		ELSE ''
	END+
	CASE
		WHEN @Gender in ('M','F') THEN '
	AND c.Gender = '+Char(39)+@Gender+Char(39)
		ELSE ''
	END +
		CASE
		WHEN @AgeRange not like '%-%' THEN ''
		ELSE '
	AND c.AgeCurrent BETWEEN '+ Replace(@AgeRange,'-',' and ')
	END+
	CASE
	WHEN @SocialClass <> '' THEN '
	AND cc.Social_Class Between '''+Replace(@SocialClass,'-',''' and ''')+''''
	ELSE ''
	END +


'
				
Create Clustered index CIX_CustomerBase_FanID on #CustomerBase (FanID)
Create NonClustered index CIX_CustomerBase_CompositeID on #CustomerBase (CompositeID)
'

+

-- ***** Comment by ZT '2017-03-03': New code to get customer base and if they are welcome  *****
 '
/****************************************************************************
*********************Get Basic Customer Info for Members*********************
****************************************************************************/
'+ 
-------------------------------------------------------------------
--		Get welcome customers from outside universe if required
-------------------------------------------------------------------

Case when @Offer4 <> 0 then 
'	IF Object_id('+CHAR(39)+'tempdb..#Welcome'+CHAR(39)+') IS NOT NULL  DROP TABLE #Welcome  
	Select	c.FanID, 
			c.CompositeID, 
			c.Gender,
			c.AgeCurrent,
			c.Postcode,
			''W'' as SOWCategory
			,NULL as ShopperSegmentTypeID
			,c.Ranking
	Into #Welcome
	From #CustomerBase c	
	Where c.ActivatedDate > '''+ cast(@activateddate as varchar(20)) +'''
	
	Create Clustered index i_Welcome_CompositeID on #Welcome (CompositeID)
	'

	Else ''
End 
+ 

-------------------------------------------------------------------
--		Get birthday and homemover customers if required
-------------------------------------------------------------------

Case 
	When @Offer5 <> 0 or @Offer6 <> 0 then 
	'	
	IF Object_id('+CHAR(39)+'tempdb..#SOW'+CHAR(39)+') IS NOT NULL  DROP TABLE #SOW  
		Select	c.FanID, 
				c.CompositeID,
				c.Gender,
				c.AgeCurrent,
				c.Postcode,
				Case ' +
					case when @Offer5 <> 0 then '
					When DATEADD(YEAR,-(DATEPART(YEAR,DOB)-1900),c.DOB) between '''+ cast(@birthdayStart as varchar(20)) +''' and '''+ cast(@BirthdayEnd as varchar(20)) +''' then ''B'' 
					' 
					Else ''
					end 	+ 
					case when @offer6 <> 0 then '
					When Homemover = 1 then ''H''
					' 
					Else ''
					end + '
				Else ''U''
			End as SOWCategory
			,NULL as ShopperSegmentTypeID
			,c.Ranking
		Into #SOW
		From #CustomerBase c ' +
		Case
			When @CustomerBaseOfferDate <> '' then '
				inner join #Members as m
				on c.CompositeID = m.CompositeID'
			Else ''
		End + 
		Case 
			when @Offer4 <> 0 then '
				Left Outer join #Welcome as w
				on w.compositeid = c.compositeid'
			Else ''
		End +
		'
		Where 1=1 and 
		' + 
		CASE
			when @Offer5 <> 0 and @Offer6 <> 0 then 
				'(DATEADD(YEAR,-(DATEPART(YEAR,DOB)-1900),c.DOB) between '''+ cast(@birthdayStart as varchar(20)) +''' and '''+ cast(@BirthdayEnd as varchar(20)) +'''  	
				 or c.Homemover = 1) ' 
			when @offer5 <> 0 then 
			'DATEADD(YEAR,-(DATEPART(YEAR,DOB)-1900),c.DOB) between '''+ cast(@birthdayStart as varchar(20)) +''' and '''+ cast(@BirthdayEnd as varchar(20)) +''' ' 
			when @offer6 <> 0 then 
			'c.Homemover = 1 ' 
			else '' 
		end +
		Case 
			when @Offer4 <> 0 then '
				And w.CompositeID is null'
			Else ''
		End  
	  + '
Create Clustered index i_SOW_CompositeID on #SOW (CompositeID)
' 
Else ''
End 

+'
-------------------------------------------------------------------
--		Get all customers on shopper segments 
-------------------------------------------------------------------

IF Object_id('+CHAR(39)+'tempdb..#ShopperSegments'+CHAR(39)+') IS NOT NULL  DROP TABLE #ShopperSegmements  
Select	c.FanID, 
		c.CompositeID, 
		c.Gender,
		c.AgeCurrent,
		c.Postcode,
		''U'' as SOWCategory
		,htm.ShopperSegmentTypeID
		,c.Ranking
Into #ShopperSegments
From #CustomerBase c
inner join Segmentation.Roc_Shopper_Segment_Members htm with (nolock)
	on c.FanId = htm.FanID
	AND htm.ShopperSegmentTypeID IN ('+@ShopperSegments+')
	and htm.PartnerId = '+ @partnerid +'
	and htm.EndDate is null' +
Case
	When @CustomerBaseOfferDate <> '' then '
inner join #Members as m
	on c.CompositeID = m.CompositeID'
	Else ''
End + 
Case when @Offer4 <> 0 then '
Left Outer join #Welcome as w
	on w.compositeid = c.compositeid'
Else ''
End +
	Case when @Offer5 <> 0 or @Offer6 <> 0 then '
Left Outer join #SOW as sow
	on sow.compositeid = c.compositeid'
Else ''
End +'
Where 1=1'+
Case when @Offer4 <> 0 then '
And w.CompositeID is null'
Else ''
End  
+
Case when @Offer5 <> 0 or @Offer6 <> 0 then '
And sow.CompositeID is null'
Else ''
End  +

'

Create Clustered index i_ShopperSegments_CompositeID on #ShopperSegments (CompositeID)
'
+
-- ***** Comment by ZT '2017-04-26': Code to merge all customers together to one table when building marketable base  *****
'
Select * 
Into #Customers
	from ( '+
	Case when @Offer4 <> 0 then '
	Select * from #Welcome
	Union ALL'
	Else ''
	End  
	+
	Case when @Offer5 <> 0 or @Offer6 <> 0 then '
	Select * from #SOW
	Union ALL'
	Else ''
	End  +'
	Select * from #ShopperSegments'+
') x

Create Clustered index i_Customers_CompositeID on #Customers (CompositeID)


/****************************************************************************
*****************Building the Marketable by Email Customer Base**************
****************************************************************************/

IF OBJECT_ID ('+char(39)+'tempdb..#CustBase'+char(39)+') IS NOT NULL DROP TABLE #CustBase
SELECT	DISTINCT
	c.FanID,
	c.CompositeID, 
	c.ShopperSegmentTypeID as ShopperSegmentID,
	''Mail'' as GRP,
	c.SOWCategory
	,c.Ranking

INTO #CustBase
FROM #Customers c '+
+'
WHERE	1=1'+
	CASE
		WHEN @NotIn_TableName1 <> '' THEN '
		AND c.FanID NOT IN (SELECT DISTINCT FanID FROM '+@NotIn_TableName1+')'
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
-- ********************** Amendment Start (ZT '2017-03-02') ********************** 
	CASE
		WHEN @MustBeIn_TableName1 <> '' THEN '
		AND c.FanID IN (SELECT DISTINCT FanID FROM '+@MustBeIn_TableName1+')'
		ELSE ''
	END+
		CASE
		WHEN @MustBeIn_TableName2 <> '' THEN '
		AND c.FanID IN (SELECT DISTINCT FanID FROM '+@MustBeIn_TableName2+')'
		ELSE ''
	END+
		CASE
		WHEN @MustBeIn_TableName3 <> '' THEN '
		AND c.FanID IN (SELECT DISTINCT FanID FROM '+@MustBeIn_TableName3+')'
		ELSE ''
	END+
		CASE
		WHEN @MustBeIn_TableName4 <> '' THEN '
		AND c.FanID IN (SELECT DISTINCT FanID FROM '+@MustBeIn_TableName4+')'
		ELSE ''
	END+

'
--**
CREATE CLUSTERED INDEX IDX_Fan ON #CustBase (FanID)

/************************************************************************
************Build Initial Selections Table, Adding Offer Codes***********
************************************************************************/
IF OBJECT_ID ('+CHAR(39)+'tempdb..#Selections'+CHAR(39)+') IS NOT NULL DROP TABLE #Selections
Select	*'
		+ Case
				When (Select Sum(LimitInCtrl) From #Throttling as t) > 0 then ',ROW_NUMBER() OVER(PARTITION BY OfferID ORDER BY ' + case when @RandomThrottle = 1 then 'NewID() ' else 'Ranking ' end + 'Asc) AS Row_Num'
				Else ''
		  End +'
INTO #Selections
From (
Select c.FanID,
	c.CompositeID,
	ShopperSegmentID as [ShopperSegmentTypeID],
	c.Ranking, 
	p.PartnerID,
	PartnerName,
	c.SOWCategory,
	CASE '+
-- ********************** Amendment Start (ZT '2017-03-02') ********************** 
-- ***** Reason for amendment: Added new code for birthday/homemover/welcome - If in a category, add customer to the offer. If the category is U (unknown) then add to shopper segment
+'
		WHEN c.SOWCategory = ''W'' THEN '+CAST(@Offer4 AS VARCHAR(5))+'
		WHEN c.SOWCategory = ''B'' THEN '+CAST(@Offer5 AS VARCHAR(5))+'
		WHEN c.SOWCategory = ''H'' THEN '+CAST(@Offer6 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 7 AND c.SOWCategory = ''U'' THEN '+CAST(@Offer1 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 8 AND c.SOWCategory = ''U'' THEN '+CAST(@Offer2 AS VARCHAR(5))+'
		WHEN ShopperSegmentID = 9 AND c.SOWCategory = ''U'' THEN '+CAST(@Offer3 AS VARCHAR(5))+

-- *********************** Amendment End  (ZT '2017-03-02') ********************** 

		' 
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
	ON p.PartnerID = '+ @PartnerID +'
) as a

'+
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 7) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 7) as varchar(10))+ '  and OfferID  = '+cast(@Offer1 as varchar(5))+'
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 8) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 8) as varchar(10))+ '  and OfferID  = '+cast(@Offer2 as varchar(5))+'
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 9) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 9) as varchar(10))+ ' and OfferID  = '+cast(@Offer3 as varchar(5))+'
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 10) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 10) as varchar(10))+ ' and OfferID  = '+cast(@Offer4 as varchar(5))+'
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 11) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 11) as varchar(10))+ ' and OfferID  = '+cast(@Offer5 as varchar(5))+'
'	Else '' End +
Case 
	When (Select LimitInCtrl From #Throttling as t where t.SegmentID = 12) > 0 then 'Delete from #Selections Where Row_Num > '+ Cast((Select LimitInCtrl From #Throttling as t where t.SegmentID = 12) as varchar(10))+ ' and OfferID  = '+cast(@Offer6 as varchar(5))+'
'	Else '' End 
+

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

'
-- ********************** Amendment Start (ZT '2017-03-02') ********************** 
-- *** Reason for amendment: No longer needed
/*
+ Case
		When @CoreSpendersToPrime = '1' then '
/*************************************************************************
****************Find Campaign Spenders and Force back In******************
*************************************************************************/
Select IronOfferID Into #OffersPast
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
	End 
	*/

-- *********************** Amendment End  (ZT '2017-03-02') ********************** 	
	
+
'/*************************************************************************
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
		[ShopperSegmentTypeID] int null,
		[SOWCategory] varchar null,
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
	ShopperSegmentTypeID,
	SOWCategory,
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
----**Check Count is Distinct
--SELECT	COUNT(1),
--	COUNT(DISTINCT FanID) 
--FROM '+ @OutputTableName + '
----**


/************************************************************************
***********************Stats for Email and Brief*************************
************************************************************************/
----**Offer Split
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
'/*
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
	CASE ' +
	-- ********************** Amendment Start (ZT '2017-03-02') ********************** 
	+ '
		WHEN ss.ShopperSegmentTypeID = 7 THEN '+CAST(@Offer1 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 8 THEN '+CAST(@Offer2 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 9 THEN '+CAST(@Offer3 AS VARCHAR(5))+
		/*'
		WHEN ss.ShopperSegmentTypeID = 10 THEN '+CAST(@Offer4 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 11 THEN '+CAST(@Offer5 AS VARCHAR(5))+'
		WHEN ss.ShopperSegmentTypeID = 12 THEN '+CAST(@Offer6 AS VARCHAR(5))+
		*/'
	END as OfferID,
	' +
	-- *********************** Amendment End  (ZT '2017-03-02') ********************** 
	+ '
	'+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
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
Select	OfferID,
		ShopperSegmentTypeID,
		Count(*) as Customers
From #CustBaseCtrl
Group by OfferID,
		 ShopperSegmentTypeID

/****************************************************************************
******************************Write to Sandbox*******************************
****************************************************************************/
Select *
Into ' +@OutputTableName+ '_OOP_Ctrl 
From #CustBaseCtrl
*/+
'

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
		When @CustomerBaseOfferDate = '' or @CustomerBaseOfferDate IS NULL then 
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

---- ********************** Amendment Start (ZT '2017-03-02') ********************** 


--SELECT @SQLCode
exec sys.sp_executesql @SQLCode
---- *********************** Amendment End  (ZT '2017-03-02') ********************** 

End