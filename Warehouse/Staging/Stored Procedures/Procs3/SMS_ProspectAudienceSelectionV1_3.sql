/*
	Author:			Suraj Chahal
	Date:			04-07-2014
	Description:	This script is to create an SMS data source
	
	Update:			We have been asked to removed ever redeemers
					14-04-2014 SB - Having trouble running, Indexes added an extra fields removed.
					09-05-2014 SB - Update field names for final output.
*/

CREATE PROCEDURE [Staging].[SMS_ProspectAudienceSelectionV1_3]
			(
	/*Declare	*/	@LionSendID INT,
			@MailGroupSize FLOAT
	--Set @LionSendID = 178
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
			INNER JOIN Relational.EmailCampaign ec WITH (NOLOCK)
				ON a.Campaignkey = ec.CampaignKey
			)
--SET @LionSendID = 166  -- LionSendID From which we would like the data extracted
--SET @MailGroupSize = 1.00 -- If there is no control group then put 1.00 otherwise put the decimal 
				-- of the percentage you want as the Mail group e.g 0.50 for a 50% mail group


/*--------------------------------------------------------------*/
---------------Creating List of People to Exclude-----------------
/*--------------------------------------------------------------*/
--Find list of all those who have had a balance over £5 previously
IF OBJECT_ID ('tempdb..#ExcludeCB') IS NOT NULL DROP TABLE #ExcludeCB
SELECT	FanID--,
	--ClubCashAvailable,
	--Date
INTO #ExcludeCB
FROM Staging.Customer_CashbackBalances t with (nolock)
WHERE	[Date] = @LastSMSDate -- Last SMS Date
	AND ClubCashAvailable >= 5

create clustered index ixc_Exc on #ExcludeCB(fanid)
/*----------------------------------------------------------------
-------------------Create List of Redeemers-----------------------
----------------------------------------------------------------*/
--Find list of all those redeemers to be removed
Select Distinct FANID
Into #Redeemers
From Relational.Redemptions as r

create clustered index ixc_Redeemers on #Redeemers(fanid)
/*----------------------------------------------------------------
-------------------Create List of over £5 Customers---------------
----------------------------------------------------------------*/
--Find all those who have a balance over £5
SELECT	FanID,ClubCashAvailable
Into #cbb
FROM	Staging.Customer_CashbackBalances with (nolock)
WHERE	ClubCashAvailable >= 5
			AND CAST([Date] AS DATE) = CAST(GETDATE() as DATE)

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
	c.FanID,
	c.ClubID,
	nlsc.LionSendID,
	ccb.ClubCashAvailable,
	c.Email,
	c.MobileTelephone,
	REPLACE(c.MobileTelephone,' ','') as Mobile_Formatted
INTO #InitialSelect
FROM Lion.NominatedLionSendComponent nlsc
INNER JOIN Relational.Customer c
	ON nlsc.CompositeID = c.CompositeID
INNER JOIN #Customers as ccb
	ON c.FanID = ccb.FanID
WHERE	nlsc.LionSendID = @LionSendID
	AND ValidMobile = 1
	AND c.ActivatedOffline = 0
	AND c.CurrentlyActive = 1
	AND RIGHT(c.MobileTelephone,6) not in ('000000','111111','222222','333333','444444','555555','666666','777777','888888','999999')
	AND c.MarketableByEmail = 1
	AND LEFT(c.FirstName,2) NOT LIKE '_.'
	AND LEN(c.FirstName) >= 2
	AND LEN(c.FirstName) <= 15
	AND c.FirstName NOT LIKE '%[!-$]%'
	AND c.FirstName NOT LIKE '%[(-+]%'
	AND c.FirstName NOT LIKE '%[\-^]%'


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