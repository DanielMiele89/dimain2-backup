/*
	Author:			Suraj Chahal
	Date:			04-07-2014
	Description:	This script is to create an SMS data source
	
	Update:			We have been asked to removed ever redeemers
					14-04-2014 SB - Having trouble running, Indexes added an extra fields removed.
					09-05-2014 SB - Update field names for final output.
					07-08-2015 SB - Warehouse problems lead to need to use SLC
*/

CREATE PROCEDURE [Staging].[SMS_ProspectAudienceSelectionV1_3_SLC_Version]
			(
	/*Declare*/	@LionSendID INT,
				@MailGroupSize FLOAT
	--Set @LionSendID = 323
	--Set @MailGroupSize = 1

			)
AS

BEGIN

/*
Title: Proposed SMS Audience Selection Code
Author: Suraj Chahal
Purpose: To automatically selection audience for SMS Campaigns
Date: 04/03/2014
*/


/*--------------------------------------------------------------*/
---------------------Declaring the variables----------------------
/*--------------------------------------------------------------*/
DECLARE @LastSMSDate DATE
	
-- To exclude anyone who was eligible at the time of the last Selection
SET @LastSMSDate =	(
			SELECT MAX(SendDate) 
			FROM Relational.SMSCampaign a WITH (NOLOCK)
			INNER JOIN Slc_report.dbo.EmailCampaign ec WITH (NOLOCK)
				ON a.Campaignkey = ec.CampaignKey
			)

/*--------------------------------------------------------------*/
---------------Creating List of People to Exclude-----------------
/*--------------------------------------------------------------*/
--Find list of all those who have had a balance over £5 previously
IF OBJECT_ID ('tempdb..#ExcludeCB') IS NOT NULL DROP TABLE #ExcludeCB
SELECT	FanID
INTO #ExcludeCB
FROM Staging.Customer_CashbackBalances t with (nolock)
WHERE	[Date] = @LastSMSDate -- Last SMS Date
	AND ClubCashAvailable >= 5

create clustered index ixc_Exc on #ExcludeCB(fanid)

/*----------------------------------------------------------------
-------------------Create List of Redeemers-----------------------
----------------------------------------------------------------*/
--Find list of all those redeemers to be removed
IF OBJECT_ID ('tempdb..#Redeemers') IS NOT NULL DROP TABLE #Redeemers
Select Distinct FANID
Into #Redeemers
From Slc_report.dbo.fan as f with (nolock)
inner join slc_report.dbo.trans as t with (nolock)
	on f.id = t.FanID
LEFT Outer JOIN (select ItemID as TransID from SLC_Report.dbo.trans t2 where t2.typeid=4) as Cancelled ON Cancelled.TransID=T.ID
Where	t.typeid = 3 and
		t.points > 0 and
		f.clubid in (132,138) and
		Cancelled.TransID is null

create clustered index ixc_Redeemers on #Redeemers(fanid)

/*----------------------------------------------------------------
-------------------Create List of over £5 Customers---------------
----------------------------------------------------------------*/
--Find all those who have a balance over £5
IF OBJECT_ID ('tempdb..#cbb') IS NOT NULL DROP TABLE #cbb
SELECT	f.ID as FanID,ClubCashAvailable
Into #cbb
FROM	slc_report.dbo.fan as f
Where	f.clubid in (132,138) and
		f.AgreedTCs = 1 and
		f.AgreedTCsDate is not null and
		f.Status = 1 and
		Coalesce(f.Unsubscribed,0) = 0 and
		Coalesce(f.hardbounced,0) = 0 and
		f.ClubCashAvailable >= 5

create clustered index ixc_cbb on #cbb(fanid)
/*---------------------------------------------------------------------------------
  --------------Exclude those who redeemed or previously has over £5---------------
  ---------------------------------------------------------------------------------*/
Select Distinct cbb.FanID,cbb.ClubCashAvailable
Into #ccb
from #cbb as cbb
Left Outer join #ExcludeCB as e
	on cbb.FanID = e.FanID
Left Outer join #Redeemers as r
	on cbb.FanID = r.FanID
Where	e.FanID is null and
		r.FanID is null

create clustered index ixc_ccb on #ccb(fanid)
/*---------------------------------------------------------------------------------
  --------------------------------Remove Previous SMS Members----------------------
  ---------------------------------------------------------------------------------*/
Select Distinct ccb.FanID,ccb.ClubCashAvailable
Into #Customers
from #ccb as ccb
Left Outer join Relational.SMSCampaignMembers  as sms
	on ccb.FanID = sms.FanID
Where sms.FanID is null

create clustered index ixc_Customers on #Customers(fanid)

/*--------------------------------------------------------------*/
-----------Creating Initial Select for eligible people------------
/*--------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#InitialSelect') IS NOT NULL DROP TABLE #InitialSelect
SELECT	DISTINCT
	c.ID as FanID,
	c.ClubID,
	nlsc.LionSendID,
	ccb.ClubCashAvailable,
	c.Email,
	c.MobileTelephone,
	REPLACE(c.MobileTelephone,' ','') as Mobile_Formatted
INTO #InitialSelect
FROM Lion.NominatedLionSendComponent nlsc
INNER JOIN slc_report.dbo.fan as c
	on nlsc.CompositeId = c.CompositeID
--Relational.Customer c
INNER JOIN #Customers as ccb
	ON c.ID = ccb.FanID
WHERE	nlsc.LionSendID = @LionSendID
	--AND ValidMobile = 1
	And Coalesce(c.OfflineOnly,0) = 0
	AND RIGHT(c.MobileTelephone,6) not in ('000000','111111','222222','333333','444444','555555','666666','777777','888888','999999')
	AND LEFT(c.FirstName,2) NOT LIKE '_.'
	AND LEN(c.FirstName) >= 2
	AND LEN(c.FirstName) <= 15
	AND c.FirstName NOT LIKE '%[!-$]%'
	AND c.FirstName NOT LIKE '%[(-+]%'
	AND c.FirstName NOT LIKE '%[\-^]%'
	and (	
			left(replace(c.MobileTelephone,' ',''),2) like '07' or
		LEFT(replace(c.MobileTelephone,' ',''),4) like '+447'
		)
	and LEN(replace(c.MobileTelephone,' ','')) >= 11 

/*--------------------------------------------------------------*/
---------Formatting the Mobile number and Row Numbering-----------
/*--------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#DataFormatted') IS NOT NULL DROP TABLE #DataFormatted
SELECT	ROW_NUMBER() OVER(ORDER BY ID DESC) AS RowNo,
	FanID,
	ClubID,
	LionSendID,
	Email,
	MobileTelephone,
	Mobile_Complete,
	ClubCashAvailable
INTO #DataFormatted
FROM	(
		SELECT	NEWID() as ID,
			FanID,
			ClubID,
			LionSendID,
			Email,
			MobileTelephone,
			CASE
				WHEN LEFT(Mobile_Formatted,2) = '07' THEN '+44'+RIGHT(Mobile_Formatted,LEN(Mobile_Formatted)-1)
				ELSE Mobile_Formatted
			END as Mobile_Complete,
			ClubCashAvailable
		FROM #InitialSelect
	)a
 WHERE LEN(Mobile_Complete) = 13



/*---------------------------------------------------------------------*/
-------------------------Adding the Control Group------------------------
/*---------------------------------------------------------------------*/
IF OBJECT_ID ('tempdb..#Ref_Vols') IS NOT NULL DROP TABLE #Ref_Vols
DECLARE @PercMail REAL
SET @PercMail = @MailGroupSize  --Control Splits

SELECT	a.*,
	CEILING(Cust_Num*@PercMail) as Mail_Num
INTO #Ref_Vols
FROM	(
	SELECT	MAX(RowNo) as Cust_Num
	FROM #DataFormatted
	) a
--(1 row(s) affected)
--SELECT * FROM #Ref_Vols

IF OBJECT_ID ('tempdb..#FinalSelection') IS NOT NULL DROP TABLE #FinalSelection
SELECT	c.*,
	v.Mail_Num,
	CASE 
		WHEN RowNo <= Mail_Num THEN 'M'
		ELSE 'C'
	END as Grp
INTO #FinalSelection
FROM #DataFormatted c,
	#Ref_Vols v 
--(13164 row(s) affected)


ALTER INDEX IDX_FanID ON Relational.SMSCampaignMembers_Proposed DISABLE
ALTER INDEX IDX_SMSCID ON Relational.SMSCampaignMembers_Proposed DISABLE

/*---------------------------------------------------------------------*/
----------------------------Final Insert--------------------------------
/*---------------------------------------------------------------------*/
INSERT INTO Relational.SMSCampaign
SELECT	NULL as CampaignKey,
	0 as Sent

DECLARE @MaxSMSID INT
SET @MaxSMSID = (SELECT MAX(SMSCampaignID) FROM Relational.SMSCampaign) 

INSERT INTO Relational.SMSCampaignMembers_Proposed
SELECT	@MaxSMSID as SMSCampaignID,
	FanID,
	Grp 
FROM #FinalSelection


ALTER INDEX IDX_FanID ON Relational.SMSCampaignMembers_Proposed REBUILD
ALTER INDEX IDX_SMSCID ON Relational.SMSCampaignMembers_Proposed REBUILD

--SELECT	*
--FROM Relational.SMSCampaignMembers_Proposed
--WHERE SMSCampaignID = @MaxSMSID

/*---------------------------------------------------------------------*/
----------------------Final Select for Marketing------------------------
/*---------------------------------------------------------------------*/
SELECT	FanID as [customer id], 
		Email,
		1 as [SMS Permission],
		Mobile_Complete as [SMS Number],
		ClubID
FROM #FinalSelection
Where GRP = 'M'



END