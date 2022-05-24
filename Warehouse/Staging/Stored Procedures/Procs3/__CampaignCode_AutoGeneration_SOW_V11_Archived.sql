

CREATE PROCEDURE [Staging].[__CampaignCode_AutoGeneration_SOW_V11_Archived]
			(@PartnerID CHAR(4),
			@Emailable BIT,
			@StartDate DATE, 
			@EndDate DATE,
			@Exclude_MOT3Week1 BIT,
			@PaymentMethodsAvailable VARCHAR(10),
			@NoSoW BIT,
			@SoW_OfferID VARCHAR(75),
			@NoSow_OfferID VARCHAR(5),
			@Gender CHAR(1),
			@AgeRange VARCHAR(7),
			@DeDupe BIT,
			@NonCoreBaseOfferMember BIT,
			@ClientServicesRef VARCHAR(10),
			@MailGroupSize CHAR(4),
			@ControlGroupPct CHAR(3),
			@OutputTableName VARCHAR (100),
			@CampaignName VARCHAR (250),
			@SelectionDate VARCHAR(11),
			@HomemoveDate DATE,
			@CampaignID_Include CHAR(3),
			@CampaignID_Exclude CHAR(3),
			@BirthdayMonth CHAR(2),
			@BirthdayInDateRange BIT,
			@ResponseIndexBandRange VARCHAR(7),
			@ActivatorDateRange VARCHAR(30),
			@OutletSector CHAR(6),
			@LiveNearAnyStore BIT, 
			@DriveTimeMins CHAR(3),
			@DeDupeAgainstCampaigns VARCHAR(50),
			@NotIn_TableName1 VARCHAR(100),
			@NotIn_TableName2 VARCHAR(100),
			@NotIn_TableName3 VARCHAR(100),
			@NotIn_TableName4 VARCHAR(100),
			@isStudent BIT,
			@SelectedInAnotherCampaign VARCHAR(50),
			@CampaignTypeID CHAR(1),
			@IsTrigger CHAR(1),
			@IncludeUC BIT,
			@UCOutputTableName VARCHAR (100)
)

AS

BEGIN
/****************************************************************************************************
Title: Auto-Generation Of Campaign Selection Code
Author: Suraj Chahal
Creation Date: 25 Sep 2014
Purpose: Automatically create campaign offer selection code which can be run by Data Operations
****************************************************************************************************/

DECLARE @SQLCode varchar(MAX),@Counter int,@TotalCASElines nvarchar(max),@HTMIDs varchar(25),@UserName Varchar(50),
		@EndDateTime datetime
SET @UserName = (SELECT CASE	WHEN USER_NAME() = 'Suraj' THEN 'Suraj Chahal'
				WHEN USER_NAME() = 'Stuart' THEN 'Stuart Barnley'
				WHEN USER_NAME() = 'Glen' THEN 'Glen Ihama'
				ELSE USER_NAME()
			END)

DECLARE @BStartDate DATE,
        @BEndDate DATE

SET @BStartDate = DATEADD(YEAR,-(DATEPART(YEAR,@StartDate)-1900),@StartDate)
SET @BEndDate = DATEADD(YEAR,-(DATEPART(YEAR,@EndDate)-1900),@EndDate)

Set @EndDateTime = Dateadd(ss,-1,Cast(Dateadd(day,1,@EndDate) as datetime))


--------------------------------------------------------------------------------
----------Create table that holds a list of OfferIDs per Headroom Segment-------
--------------------------------------------------------------------------------
IF OBJECT_ID ('tempdb..#OfferIDs') IS NOT NULL DROP TABLE #OfferIDs
Create table #OfferIDs (HTMID int, OfferID int,OfferString Varchar(100))
Set @Counter = 10
While @Counter <= 16 -- Loop around all nine offerIDs, it assumes something entered for all nine (0000 if no offer id)
Begin 
	Insert into #OfferIDs
	Select	@Counter as HTMID, --HTMID based on order of OfferIDS
			Left(@SoW_OfferID,5) as OfferID, --OfferID
			'WHEN c.HTMID = ' + Cast(@Counter as char(2))+' THEN ' + Left(@SoW_OfferID,5) as OfferString --String of text used by CASE statement to assign offers to HTM Segments
	Set @SoW_OfferID = (CASE
						WHEN @Counter < 16 THEN Right(@SoW_OfferID,Len(@SoW_OfferID)-6)
						ELSE @SoW_OfferID
			END )  -- Remove OfferID just logged
	Set @Counter = @Counter+1
END

Set @TotalCASElines = 
 (	select  OfferString+ '
		' as 'text()' 				
	from #OfferIDs
	Where OfferID > 0
	for xml path('')
 ) -- Create one field with all WHEN statements where offer exists

Set @TotalCASELines = Replace(@TotalCASELines,'&#x0D;','') --- remove xml carriage return values

Set @HTMIDs = 
  (	Select  Cast(HTMID as char(2))+ ',' as 'text()' 				
	from #OfferIDs
	Where OfferID > 0
	for xml path('') --- Create one string of all HTMIDs needed for this campaign
 )

Set @HTMIDs = (CASE
		WHEN right(replace(@HTMIDs,' ',''),1) = ',' THEN
					Replace('('+Left(@HTMIDs,Len(@HTMIDs)-1)+')',' ','') -- remove extra comma and spaces
		ELSE '('+Replace(@HTMIDs,' ','')+')'
		END)

SET @SQLCode = ''

SET @SQLCode = @SQLCode+

'
/*******************************************************
Campaign: '+ @ClientServicesRef + ' - '+ @CampaignName + '
Selection Date: '+ @SelectionDate + '
Executed by: '+ @UserName + '
Output Table Name: '+ @OutputTableName + '
*******************************************************/

'+
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
+'

'+
CASE	WHEN @Exclude_MOT3Week1 = 1
	THEN '

/************************************************
***************Exclude MOT3 Week 1***************
************************************************/
DECLARE @MAX_AddedDate DATE
SET @MAX_AddedDate = (SELECT MAX(AddedDate) FROM Warehouse.Staging.MOT3Week1_Exclusions)

IF OBJECT_ID (''tempdb..#MOT3_Week1'') IS NOT NULL DROP TABLE #MOT3_Week1
SELECT	mt.FanID
INTO #MOT3_Week1
FROM Warehouse.Staging.MOT3Week1_Exclusions mt
INNER JOIN Warehouse.Relational.CustomerJourney cj
	ON mt.FanID = cj.FanID
	AND cj.EndDate IS NULL
WHERE	AddedDate = @MAX_AddedDate
	AND cj.Shortcode LIKE ''M3%''
--
CREATE CLUSTERED INDEX IDX_FID ON #MOT3_Week1 (FanID)
'
	ELSE ''
END+
'

/****************************************************************************
*****************Building the Marketable by Email Customer Base**************
****************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#CustBase'+char(39)+') IS NOT NULL DROP TABLE #CustBase
SELECT	DISTINCT
	c.FanID,
	c.CompositeID, 
	c.MarketableByEmail,
	c.PostalSector'+
	CASE	WHEN @NoSoW = 0
		THEN +',
	htm.HTMID,
	htg.HTM_Description'
	ELSE 
	',
	NULL as HTMID,
	NULL as HTM_Description'	
	END +'
INTO #CustBase
FROM Warehouse.Relational.Customer c
INNER JOIN Warehouse.Relational.CustomerPaymentMethodsAvailable cpm
	ON c.FanID = cpm.FanID
	AND cpm.EndDate IS NULL
	AND cpm.PaymentMethodsAvailableID IN ('+@PaymentMethodsAvailable+')
LEFT OUTER JOIN Warehouse.Relational.Customers_ReducedFrequency_CurrentExclusions ce
      ON c.FanID = ce.FanID'+
CASE	WHEN @NoSoW = 0
	THEN '
INNER JOIN Warehouse.Relational.ShareOfWallet_Members htm (NOLOCK)
	ON c.FanID = htm.FanID
	AND htm.PartnerID = ' + @PartnerID + '
	AND htm.EndDate IS NULL
	AND htm.HTMID IN ' + @HTMIDs +'
INNER JOIN Warehouse.Relational.HeadroomTargetingModel_Groups htg (NOLOCK)
	ON htm.HTMID = htg.HTMID' 
	ELSE ''
END+
CASE	WHEN @ResponseIndexBandRange <> ''
	THEN '
INNER JOIN Warehouse.Relational.GeoDemographicHeatMap_Members geo (NOLOCK)
	ON c.FanID = geo.FanID
	AND geo.PartnerID = ' + @PartnerID + '
	AND geo.EndDate IS NULL
	AND geo.ResponseIndexBand_ID BETWEEN ' + LEFT(@ResponseIndexBandRange,CHARINDEX('-', @ResponseIndexBandRange)-1)+' AND '+ 
								RIGHT(RTRIM(@ResponseIndexBandRange),LEN(RTRIM(@ResponseIndexBandRange))-CHARINDEX('-', @ResponseIndexBandRange))
	ELSE ''
END+
CASE	WHEN @isStudent = 1
	THEN '
INNER JOIN Warehouse.Relational.CBP_StudentAccountHolders stu
	ON c.FanID = stu.FanID'
	ELSE ''
END+
CASE	WHEN @Emailable = 1
	THEN '
LEFT OUTER JOIN Warehouse.Relational.SmartFocusUnSubscribes un
	ON c.FanID = un.FanID
	AND un.EndDate IS NULL'
	ELSE ''
END+
CASE	WHEN @DeDupe = 1 AND @NonCoreBaseOfferMember = 0
	THEN '
LEFT OUTER JOIN (
		SELECT	DISTINCT 
			FanID
		FROM Warehouse.Relational.Campaign_History (NOLOCK)
		WHERE	PartnerID = ' + @PartnerID + '
			AND EDate >= Cast('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+ ' as date)
		)cha
	ON c.FanID = cha.FanID'
	WHEN @DeDupe = 1 AND @NonCoreBaseOfferMember = 1
	THEN '
LEFT OUTER JOIN (
		SELECT	DISTINCT 
			FanID
		FROM Warehouse.Relational.Campaign_History cha (NOLOCK)
		LEFT OUTER JOIN Warehouse.Relational.Partner_NonCoreBaseOffer ncb
			ON  cha.PartnerID = ncb.PartnerID 
			AND cha.IronOfferID = ncb.IronOfferID
			AND CAST(ncb.EndDate AS DATE) >= Cast('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+ ' as date) 
		WHERE	cha.PartnerID = ' + @PartnerID + '
			AND EDate >= Cast('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+ ' as date)
			AND ncb.IronOfferID IS NULL
		
		)cha
	ON c.FanID = cha.FanID'
	ELSE ''
END+
CASE	WHEN @DeDupeAgainstCampaigns <> ''
	THEN '
LEFT OUTER JOIN (
		SELECT	DISTINCT 
			ch.FanID 
		FROM Warehouse.Relational.IronOffer_Campaign_HTM htm
		INNER JOIN Warehouse.Relational.Campaign_History ch
			ON htm.IronOfferID = ch.IronOfferID 
		WHERE	htm.ClientServicesRef IN ('+Char(39)+Replace(@DeDupeAgainstCampaigns,',',''',''')+Char(39)+')
		)ioh
	ON c.FanID = ioh.FanID'
	ELSE ''
END+
CASE	WHEN @SelectedInAnotherCampaign <> ''
	THEN '
INNER JOIN (	
		SELECT	DISTINCT 
			ch.FanID 
		FROM Warehouse.Relational.IronOffer_Campaign_HTM htm
		INNER JOIN Warehouse.Relational.Campaign_History ch
			ON htm.IronOfferID = ch.IronOfferID 
		WHERE	htm.ClientServicesRef IN ('''+Replace(@SelectedInAnotherCampaign,',',Char(39)+','+Char(39))+''')
			AND Grp = ''Mail''
		)oc
	ON c.FanID = oc.FanID'
	ELSE ''
END+
CASE	WHEN @OutletSector <> '' AND @DriveTimeMins <> ''
	THEN '
INNER JOIN Warehouse.Relational.DriveTimeMatrix dt 
	ON c.PostalSector = dt.FromSector
	AND (ToSector IN ('''+@OutletSector+''') AND DriveTimeMins <= '+@DriveTimeMins +')'
	ELSE ''
END+

CASE	WHEN @HomemoveDate <> '' AND @CampaignID_Include <> '' THEN'
LEFT OUTER JOIN Warehouse.Relational.Homemover_Details AS h
	ON c.FanID = h.FanID
	AND LoadDate >= Cast('+ CHAR(39) + convert(varchar, @HomemoveDate, 107) + CHAR(39)+ ' as date)
LEFT OUTER JOIN Warehouse.Relational.PartnerTrigger_Members AS ptm
	ON c.FanID = ptm.FanID
	AND ptm.CampaignID = '+ @CampaignID_Include
	WHEN @HomemoveDate >= 'Jan 01, 1901' THEN'
INNER JOIN Warehouse.Relational.Homemover_Details AS h
	ON c.FanID = h.FanID
	AND LoadDate >= Cast('+ CHAR(39) + convert(varchar, @HomemoveDate, 107) + CHAR(39)+ ' as date)'
	WHEN @CampaignID_Include <> '' THEN'
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
END+
CASE	WHEN @Exclude_MOT3Week1 = 1
	THEN '
LEFT OUTER JOIN	#MOT3_Week1 mot3
	ON c.FanID = mot3.FanID'
	ELSE ''
END+'
WHERE	c.CurrentlyActive = 1
	AND ce.FanID IS NULL
	AND LEN(c.PostCode) >= 3'+
	CASE
		WHEN @Emailable = 1 THEN ' 
	AND c.Marketablebyemail = 1'
		ELSE ''
	END +
	CASE
		WHEN @GENDer = 'M' THEN '
	AND c.Gender = '+Char(39)+'M'+Char(39)
		WHEN @GENDer = 'F' THEN '
	AND c.Gender = '+Char(39)+'F'+Char(39)
		ELSE ''
	END +
	CASE
		WHEN @AgeRange not like '%-%' THEN ''
		ELSE '
	AND c.AgeCurrent BETWEEN '+ left(@AgeRange,charindex('-', @AgeRange)-1)+' AND '+ 
								Right(rtrim(@AgeRange),Len(rtrim(@AgeRange))-charindex('-', @AgeRange))								
	END+
	CASE
		WHEN @DeDupe = 1 THEN '
	AND cha.FanID IS NULL'
		ELSE ''
	END+
	CASE
		WHEN @Emailable = 1 THEN ' 
	AND un.FanID IS NULL'
		ELSE ''
	END +
	CASE
		WHEN @BirthdayMonth <> '' THEN ' 
	AND MONTH(c.DOB) = '+@BirthdayMonth
		ELSE ''
	END +
	CASE
		WHEN @BirthdayInDateRange <> 0 THEN ' 
	AND DATEADD(YEAR,-(DATEPART(YEAR,DOB)-1900),c.DOB) BETWEEN '''+ CONVERT(VARCHAR,@BStartDate,107) +''' and '''+CONVERT(VARCHAR,@BEndDate,107)+CHAR(39)
		ELSE ''
	END +
	CASE
		WHEN @HomemoveDate <> '' AND @CampaignID_Include <> '' THEN '
	AND (h.FanID IS NOT NULL OR ptm.FanID IS NOT NULL)'
		ELSE ''
	END+
	CASE
		WHEN @DeDupeAgainstCampaigns <> '' THEN '
	AND ioh.FanID IS NULL'
		ELSE ''
	END+	
	CASE
		WHEN @CampaignID_Exclude <> '' THEN '
	AND ptm2.FanID IS NULL'
		ELSE ''
	END+
	CASE
		WHEN @Exclude_MOT3Week1 = 1 THEN '
	AND mot3.FanID IS NULL'
		ELSE ''
	END+
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
	CASE
		WHEN @ActivatorDateRange <> '' THEN '
	AND c.ActivatedDate BETWEEN '+char(39)+left(@ActivatorDateRange,charindex('-', @ActivatorDateRange)-1)+char(39)+' AND '+ 
								char(39)+Right(rtrim(@ActivatorDateRange),Len(rtrim(@ActivatorDateRange))-charindex('-', @ActivatorDateRange))+char(39)
		ELSE ''
	END+
	'
--**
CREATE CLUSTERED INDEX IDX_Fan ON #CustBase (FanID)

'+

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
	FROM #CustBase cb
	INNER JOIN Warehouse.Relational.DriveTimeMatrix dtm
		ON cb.PostalSector = dtm.FromSector
	INNER JOIN #PostalSectors ps
		ON dtm.ToSector = ps.PostalSector
		AND dtm.DriveTimeMins <= '+@DriveTimeMins +'
	) a
WHERE RowNo = 1
--**
CREATE CLUSTERED INDEX IDX_FanID ON #CustsInRange (FanID)


--**Checking
SELECT	COUNT(1),
	COUNT(DISTINCT FanID)
FROM #CustsInRange
--**

SELECT	cb.FanID,
	cb.PostalSector as Customer_PostCode,
	cb.OutletPostalSector,
	dtm.DriveTimeMins
FROM #CustsInRange cb	
INNER JOIN Warehouse.Relational.DriveTimeMatrix dtm
	ON cb.PostalSector = dtm.FromSector
	AND cb.OutletPostalSector = dtm.ToSector
WHERE dtm.DriveTimeMins > '+@DriveTimeMins +'
--**

'
	ELSE ''
END+
'
/************************************************************************
************Build Initial Selections Table, Adding Offer Codes***********
************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#Selections'+char(39)+') IS NOT NULL DROP TABLE #Selections
SELECT	'+
	CASE
		WHEN @NoSoW = 0 THEN 
	'ROW_NUMBER() OVER(PARTITION BY c.HTMID ORDER BY NEWID()) as row_num,'
		ELSE 
	'ROW_NUMBER() OVER(ORDER BY NEWID()) as row_num,'
	END+ '	
	c.FanID,
	c.CompositeID,
	c.MarketableByEmail,
	c.HTMID,
	c.HTM_Description,
	p.PartnerID,
	PartnerName,
	'+
	CASE	WHEN @NoSoW = 0 THEN '
	CASE
		' +@TotalCASElines+'
	END as OfferID,'
		ELSE
	@NoSow_OfferID+' as OfferID,'
	END+'		  
	'+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
	CAST(NULL AS DATE) as StartDate,
	CAST(NULL AS DATE) as EndDate,
	'+char(39)+'E'+char(39)+' as [Comm Type],
	CAST(NULL AS VARCHAR(5)) as TriggerBatch
INTO #Selections
FROM #CustBase c
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = '+ @PartnerID
+
CASE
	WHEN @LiveNearAnyStore = 1 AND @DriveTimeMins <> '' THEN '
INNER JOIN #CustsInRange cir
	ON c.FanID = cir.FanID'
	ELSE ''
END+
'
--**
 
--**Check Splits by SoW and OfferID
SELECT	HTMID,
	HTM_Description,
	COUNT(1)
FROM #Selections
GROUP BY HTMID,HTM_Description
ORDER BY HTMID


SELECT	OfferID,
	COUNT(1)
FROM #Selections
GROUP BY OfferID
ORDER BY OfferID


/************************************************************************
*************************Adding the Control Group************************
************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#Ref_Vols'+char(39)+') IS NOT NULL DROP TABLE #Ref_Vols
DECLARE @PercMail REAL
SET @PercMail = '+ @MailGroupSize +'  --Control Splits

SELECT	a.*,
	CEILING(Cust_Num*@PercMail) as Mail_Num
INTO #Ref_Vols
FROM	(
	SELECT	MAX(row_num) as Cust_Num,
		'+
		CASE
			WHEN @NoSoW = 0 THEN 
		'HTMID
	FROM #Selections
	GROUP BY HTMID
		) a'
			ELSE 
		'OfferID
	FROM #Selections
	GROUP BY OfferID
		) a'
		END+ '
--**

IF OBJECT_ID ('+char(39)+'tempdb..#Final'+char(39)+') IS NOT NULL DROP TABLE #Final
SELECT	c.*,
	v.Mail_Num,
	CASE 
		WHEN row_num <= Mail_Num THEN '+char(39)+'Mail'+char(39)+'
		ELSE '+char(39)+'Control'+char(39)+'
	END as Grp
'+
		CASE
			WHEN @NoSoW = 0 THEN 
'
INTO #Final
FROM #Selections c
LEFT OUTER JOIN #Ref_Vols v 
	ON c.HTMID = v.HTMID
--**

SELECT	HTMID,
	HTM_Description,
	Grp,
	COUNT(1)
FROM #Final
GROUP BY HTMID,HTM_Description, Grp
ORDER BY HTMID
'
			ELSE 
'
INTO #Final
FROM #Selections c
LEFT OUTER JOIN #Ref_Vols v 
	ON c.OfferID = v.OfferID
--**

SELECT	OfferID,
	Grp,
	COUNT(1)
FROM #Final
GROUP BY OfferID, Grp
ORDER BY OfferID
'
		END+ '


/*************************************************************************
***********Adding a new Row Number from which we can chunk size***********
*************************************************************************/
ALTER TABLE #Final
DROP COLUMN Row_Num


SELECT	ROW_NUMBER() over(order by FanID) as  SelectionID,
	*
INTO #FinalSelection
FROM #Final
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
SELECT	COUNT(1)
FROM #FinalSelection
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
	PartnerID,
	PartnerName,
	OfferID,
	ClientServicesRef,
	CAST('+ CHAR(39) + convert(varchar, @StartDate, 107) + CHAR(39)+' AS DATE) as StartDate,
	CAST('+ CHAR(39) + convert(varchar, @EndDateTime, 25) + CHAR(39)+' AS DATETime) as EndDate,
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
SELECT	COUNT(1),
	COUNT(DISTINCT FanID) 
FROM '+ @OutputTableName + '
--**


/************************************************************************
***********************Stats for Email and Brief*************************
************************************************************************/
--**Find Counts for Email and Brief
--**SOW Split
SELECT	HTMID,
	HTM_Description,
	CashbackRate,
	SUM(CASE WHEN s.Grp = '+char(39)+'Mail'+char(39)+' THEN 1 ELSE 0 END) as MailedCustomers,
	SUM(CASE WHEN s.Grp = '+char(39)+'Control'+char(39)+' THEN 1 ELSE 0 END) as ControlCustomers,
	OfferID,
	CommissionRate
FROM '+ @OutputTableName + ' s
LEFT OUTER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END)/100 as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
	ON s.OfferID = pcr.RequiredIronOfferID
GROUP BY HTMID, HTM_Description, OfferID, CashbackRate, CommissionRate
ORDER BY HTMID

--**Offer Split
SELECT	OfferID,
	CashbackRate,
	SUM(CASE WHEN s.Grp = '+char(39)+'Mail'+char(39)+' THEN 1 ELSE 0 END) as MailedCustomers,
	SUM(CASE WHEN s.Grp = '+char(39)+'Control'+char(39)+' THEN 1 ELSE 0 END) as ControlCustomers,
	CommissionRate
FROM '+ @OutputTableName + ' s
LEFT OUTER JOIN		(
			SELECT	RequiredIronOfferID,
				MAX(CASE WHEN Status = 1 AND TypeID = 1 THEN CommissionRate END)/100 as CashbackRate,
				CAST(MAX(CASE WHEN Status = 1 AND TypeID = 2 THEN CommissionRate END) AS NUMERIC(32,2)) as CommissionRate
			FROM slc_report.dbo.PartnerCommissionRule p
			WHERE RequiredIronOfferID IS NOT NULL
			GROUP BY RequiredIronOfferID
			) pcr
	ON s.OfferID = pcr.RequiredIronOfferID
GROUP BY OfferID, CashbackRate, CommissionRate
ORDER BY OfferID


/****************************************************************
*******Add new campaign to NominatedOfferMember_TableNames*******
****************************************************************/
INSERT INTO Warehouse.Relational.NominatedOfferMember_TableNames
SELECT	'''+ @OutputTableName + ''' as TableName

SELECT	*
FROM Warehouse.Relational.NominatedOfferMember_TableNames
ORDER BY TableID


/********************************************************
**********Add new campaign to CBP_CampaignNames**********
********************************************************/
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

SELECT	* 
FROM Warehouse.Relational.CBP_CampaignNames
WHERE ClientServicesRef = '''+ @ClientServicesRef + '''


/************************************************************
***********Add new campaign to IronOffer_Campaign_Type*******
************************************************************/
SELECT	ID,
	ClientServicesRef,
	CampaignTypeID,
	IsTrigger,
	ControlPercentage
FROM Warehouse.Staging.IronOffer_Campaign_Type
WHERE ClientServicesRef = '''+ @ClientServicesRef + '''


INSERT INTO Warehouse.Staging.IronOffer_Campaign_Type
SELECT	DISTINCT ClientServicesRef,
	'+@CampaignTypeID+' as CampaignTypeID, 
	'+@IsTrigger+' as IsTrigger,
	'+@ControlGroupPct+' as ControlPercentage
FROM '+ @OutputTableName + '
WHERE	ClientServicesRef NOT IN (SELECT DISTINCT ClientServicesRef FROM Warehouse.Staging.IronOffer_Campaign_Type)
--**

SELECT	*
FROM Warehouse.Staging.IronOffer_Campaign_Type
WHERE ClientServicesRef = '''+ @ClientServicesRef + '''
'

SELECT @SQLCode

IF @IncludeUC = 1
BEGIN


DECLARE @SQLCode2 varchar(MAX)

SET @SQLCode2 = 
'
/*********************************************************************************
Unstratified Control Selection: '+ @ClientServicesRef + ' - '+ @CampaignName + '
Selection Date: '+ @SelectionDate + '
Executed by: '+ @UserName + '
Output Table Name: '+ @UCOutputTableName + '
*********************************************************************************/

'+
CASE	WHEN @CampaignID_Include <> ''
	THEN '
EXEC Warehouse.Staging.Partner_GenerateTriggerMember_UC '+@CampaignID_Include
	ELSE ''
END
+'
'+
CASE	WHEN @CampaignID_Exclude <> ''
	THEN '
EXEC Warehouse.Staging.Partner_GenerateTriggerMember_UC '+@CampaignID_Exclude
	ELSE ''
END
+'


/************************************************************************
******************Building the Unstratified Control Base*****************
************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#CustBase'+char(39)+') IS NOT NULL DROP TABLE #CustBase
SELECT	FanID,
	CompositeID,
	HTMID,
	HTM_Description
INTO #CustBase
FROM	(
	SELECT	DISTINCT
		cu.FanID,
		f.CompositeID'+
	CASE	WHEN @NoSoW = 0
		THEN +',
		htm.HTMID,
		htg.HTM_Description,'
	ELSE 
		',
		NULL as HTMID,
		NULL as HTM_Description,'	
	END +'
		CAST	(	
			CASE	
				WHEN f.dob > CAST(GETDATE() AS DATE) THEN 0
				WHEN MONTH(f.DOB) > MONTH(GETDATE())THEN DATEDIFF(YYYY,f.DOB,GETDATE())-1 
				WHEN MONTH(f.DOB) < MONTH(GETDATE()) THEN DATEDIFF(YYYY,f.DOB,GETDATE()) 
				WHEN MONTH(f.DOB) = MONTH(GETDATE()) THEN 
								CASE WHEN DAY(f.DOB)>DAY(GETDATE()) THEN DATEDIFF(YYYY,f.DOB,GETDATE())-1 
								ELSE DATEDIFF(YYYY,f.DOB,GETDATE()) 
			END 
		END AS TINYINT) as AgeCurrent
	FROM Warehouse.Relational.Control_Unstratified cu
	INNER JOIN SLC_Report.dbo.Fan f
		ON cu.FanID = f.ID
	LEFT OUTER JOIN Warehouse.Relational.Customer c
		ON cu.FanID = c.FanID'+
	CASE	WHEN @NoSoW = 0
		THEN '
	INNER JOIN Warehouse.Relational.ShareOfWallet_Members_UC htm (NOLOCK)
		ON cu.FanID = htm.FanID
		AND htm.PartnerID = ' + @PartnerID + '
		AND htm.EndDate IS NULL
		AND htm.HTMID IN ' + @HTMIDs +'
	INNER JOIN Warehouse.Relational.HeadroomTargetingModel_Groups htg (NOLOCK)
		ON htm.HTMID = htg.HTMID' 
		ELSE ''
	END+
	CASE
		WHEN @CampaignID_Include <> '' THEN'
	INNER JOIN Warehouse.Relational.PartnerTrigger_UC_Members AS ptm
		ON cu.FanID = ptm.FanID
		AND ptm.CampaignID = '+ @CampaignID_Include
		ELSE ''
	END+
	CASE	WHEN @CampaignID_Exclude <> ''
		THEN '
	LEFT OUTER JOIN Warehouse.Relational.PartnerTrigger_UC_Members AS ptm2
		ON cu.FanID = ptm2.FanID
		AND ptm2.CampaignID = '+ @CampaignID_Exclude
		ELSE ''
	END+
	'
	WHERE	cu.EndDate IS NULL
		AND c.FanID IS NULL'+
		CASE
			WHEN @BirthdayMonth = '' AND @CampaignID_Exclude = ''
			THEN '
	)a'
			ELSE ''
		END+
		CASE
			WHEN @BirthdayMonth <> '' AND @CampaignID_Exclude = '' THEN ' 
		AND MONTH(f.DOB) = '+@BirthdayMonth+
			'
	)a'
			WHEN @BirthdayMonth <> '' AND @CampaignID_Exclude <> '' THEN ' 
		AND MONTH(f.DOB) = '+@BirthdayMonth
			ELSE ''
		END +
		CASE
			WHEN @CampaignID_Exclude <> '' THEN '
		AND ptm2.FanID IS NULL
	)a'
			ELSE ''
		END+
CASE
	WHEN @AgeRange not like '%-%' THEN ''
	ELSE '
WHERE AgeCurrent BETWEEN '+ left(@AgeRange,charindex('-', @AgeRange)-1)+' AND '+ 
							Right(rtrim(@AgeRange),Len(rtrim(@AgeRange))-charindex('-', @AgeRange))								
END+	
'
--
CREATE CLUSTERED INDEX IDX_Fan ON #CustBase (FanID)


/************************************************************************
************Build Initial Selections Table, Adding Offer Codes***********
************************************************************************/
IF OBJECT_ID ('+char(39)+'tempdb..#FinalSelection'+char(39)+') IS NOT NULL DROP TABLE #FinalSelection
SELECT	'+
	CASE
		WHEN @NoSoW = 0 THEN 
	'ROW_NUMBER() OVER(PARTITION BY c.HTMID ORDER BY NEWID()) as row_num,'
		ELSE 
	'ROW_NUMBER() OVER(ORDER BY NEWID()) as row_num,'
	END+ '	
	c.FanID,
	c.CompositeID,
	c.HTMID,
	c.HTM_Description,
	p.PartnerID,
	PartnerName,
	'+
	CASE	WHEN @NoSoW = 0 THEN '
	CASE
		' +@TotalCASElines+'
	END as OfferID,'
		ELSE
	@NoSow_OfferID+' as OfferID,'
	END+'  
	'+char(39)+''+@ClientServicesRef+''+char(39)+' as ClientServicesRef,
	NULL as TriggerBatch
INTO #FinalSelection
FROM #CustBase c
INNER JOIN Warehouse.Relational.Partner p
	ON p.PartnerID = '+ @PartnerID
+'
--
 
--Check Splits
SELECT	HTMID,
	HTM_Description,
	COUNT(1)
FROM #FinalSelection
GROUP BY HTMID,HTM_Description
ORDER BY HTMID


SELECT	OfferID,
	COUNT(1)
FROM #FinalSelection
GROUP BY OfferID
ORDER BY OfferID


/*************************************************************************
**************Build the final selection table Infrastructure**************
*************************************************************************/
CREATE TABLE ' +@UCOutputTableName+ '
		(
		[FanID] [int] NOT NULL PRIMARY KEY,
		[CompositeID] [bigint] NULL,
		[HTMID] [int] NULL,
		[HTM_Description] [varchar](50) NULL,
		[PartnerID] [int] NOT NULL,
		[PartnerName] [varchar](100) NOT NULL,
		[OfferID] [int] NULL,
		[ClientServicesRef] [varchar](10) NOT NULL,
		[TriggerBatch] [int] NULL
		)

/*********************************************************************************
********************Insert Targetted Offers to Selection Table********************
*********************************************************************************/
SELECT COUNT(1)FROM #FinalSelection
--

/***************************************************************
**********************Declare the variables*********************
***************************************************************/
DECLARE @StartRow INT,
	@ChunkSize INT
SET @StartRow = 0
SET @ChunkSize = 500000

/********************************************************
************************Insert***************************
********************************************************/
WHILE EXISTS (SELECT 1 FROM #FinalSelection WHERE SelectionID > @StartRow)
BEGIN
---------------------------------------------
INSERT INTO ' +@UCOutputTableName+ '
SELECT	TOP	
	(@ChunkSize)
	FanID,
	CompositeID,
	HTMID,
	HTM_Description,
	PartnerID,
	PartnerName,
	OfferID,
	ClientServicesRef,
	TriggerBatch
FROM #FinalSelection
WHERE SelectionID > @StartRow
ORDER BY SelectionID

SET @StartRow = (SELECT COUNT(1) FROM '+ @UCOutputTableName +')

END


/**************************************************************
***************************Testing*****************************
**************************************************************/
--Check Count is Distinct
SELECT COUNT(DISTINCT FanID) FROM '+ @UCOutputTableName + '
--

'
SELECT @SQLCode2



END


END