
CREATE PROCEDURE [Staging].[SMS_ProspectAudienceSelection]
			(
			@LionSendID INT,
			@MailGroupSize FLOAT
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
IF OBJECT_ID ('tempdb..#ExcludeCB') IS NOT NULL DROP TABLE #ExcludeCB
SELECT	FanID,
	ClubCashAvailable,
	Date
INTO #ExcludeCB
FROM Staging.Customer_CashbackBalances t 
WHERE	[Date] = @LastSMSDate -- Last SMS Date
	AND ClubCashAvailable >= 5



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
INNER JOIN (	SELECT	FanID,
			ClubCashAvailable
		FROM Staging.Customer_CashbackBalances 
		WHERE	ClubCashAvailable >= 5
			AND CAST([Date] AS DATE) = CAST(GETDATE() as DATE)
	  ) ccb	
	ON c.FanID = ccb.FanID
	AND ccb.ClubCashAvailable >= 5
LEFT OUTER JOIN Relational.SMSCampaignMembers sms
	ON c.FanID = sms.FanID
LEFT OUTER JOIN #ExcludeCB ecb
	ON c.FanID = ecb.FanID
WHERE	sms.FanID IS NULL
	AND ecb.FanID IS NULL
	AND nlsc.LionSendID = @LionSendID
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


--SELECT	*
--FROM Relational.SMSCampaignMembers_Proposed
--WHERE SMSCampaignID = @MaxSMSID

/*---------------------------------------------------------------------*/
----------------------Final Select for Marketing------------------------
/*---------------------------------------------------------------------*/
SELECT	FanID as [Customer ID], 
		Email,
		1 as SMS,
		--MobileTelephone,
		Mobile_Complete as [SMS Number],
		ClubID--,
		--Case
		--	When Grp = 'C' then 'Control'
		--	When Grp = 'M' then 'Mail'
		--	Else ''
		--End as Grp
FROM #FinalSelection
Where GRP = 'M'



END
