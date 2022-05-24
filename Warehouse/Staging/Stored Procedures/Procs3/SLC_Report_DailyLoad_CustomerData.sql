/*

*/

CREATE Procedure [Staging].[SLC_Report_DailyLoad_CustomerData]
with Execute as Owner
As

----------------------------------------------------------------------------------------
------------------------------------Add entry to JobLog---------------------------------
----------------------------------------------------------------------------------------


Insert into staging.JobLog_Temp
Select	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_CustomerData',
		TableSchemaName = 'SmartEmail',
		TableName = 'SmartEmail_OldSFD_CustomerData',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

----------------------------------------------------------------------------------------
-----------------------------Find Accounts and IronOfferIDs-----------------------------
----------------------------------------------------------------------------------------

Declare @time DATETIME,
		@msg VARCHAR(2048)

SELECT @msg = '#Customers Population Start'
	EXEC staging.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#Customers') is not null drop table #Customers
Select	f.Email,
		f.ClubID,
		f.Title AS [Title],
		f.FirstName AS [FirstName],
		f.LastName AS [Lastname],
		RIGHT(RTRIM(f.POSTCODE),3) AS [partial postcode],
			f.ActivationChannel,
		CASE f.ClubID
				  WHEN 132 THEN CONVERT(VARCHAR(300), ('https://www.cashbackplus.natwest.com/Account/OneClick/' + f.SourceUID + '/' + CONVERT(VARCHAR(36), z.ActivationLinkGUID)))
				  ELSE  CONVERT(VARCHAR(300), ('https://www.cashbackplus.rbs.com/Account/OneClick/' + f.SourceUID + '/' + CONVERT(VARCHAR(36), z.ActivationLinkGUID)))
		END AS [RegistrationLink],
		f.ID AS [customer id],
		CASE WHEN c.HashedPassword = N'' THEN 0
			 ELSE 1
		END AS IsRegistered,
		f.AgreedTcsDate,
		f.dob,
		ROW_NUMBER() OVER(ORDER BY f.ID DESC) AS RowNum
Into #Customers
From slc_report.dbo.fan as f
INNER JOIN slc_report.dbo.FanCredentials c WITH (NOLOCK) 
			ON f.id = c.FanID
LEFT JOIN slc_report.Zion.Member_OneClickActivation z WITH (NOLOCK) 
			ON f.ID = z.FanID AND COALESCE(z.LinkActive,1) = 1
Where	AgreedTCsDate is not null and
		Status = 1 and
		AgreedTCs = 1 and
		ClubID in (132,138)
		--and (f.OfflineOnly = 0  or f.OfflineOnly is null) -- 16 Secs
		--and dbo.fn_IsValidEmail(f.email) = 1
		and f.DeceasedDate is null

Create Clustered index CIX_Customers_FanID on #Customers ([customer id])

SELECT @msg = '#Customers Population End'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

-----------------------------------------------------------------------------------------------------
--------------------------------------------Find out balances----------------------------------------
-----------------------------------------------------------------------------------------------------

SELECT @msg = '#Balances Population Start'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

Declare @RowNo int = 1, 
		@RowNoMax int,
		@ChunkSize int = 500000,
		@RowNoChunk int

Set @RowNoMax = (Select Max(RowNum) From #Customers)

if object_id('tempdb..#Balances') is not null drop table #Balances
Create Table #Balances (FanID int, clubcashpending smallmoney, ClubCashAvailable smallmoney)

While @RowNo <= @RowNoMax
Begin
		Set @RowNoChunk = @RowNo+(@ChunkSize-1)
		Insert into #Balances
		select f.fanid,
				sum(tt.multiplier*t.clubcash) clubcashpending, 
				sum(
					case when f.clubid not in (132, 138) and (tt.multiplier<0 or t.activationdays=-1 or dateadd(d,t.activationdays,t.date)<getdate())
						then tt.multiplier*t.clubcash 

						when f.clubid in (132, 138) and ((tt.multiplier<0 and t.TypeID <> 10) or t.activationdays=-1 or dateadd(d,t.activationdays,t.date)<getdate())
						then tt.multiplier*t.clubcash 

					else 0 
					end
				) clubcashavailable
			from (Select [Customer ID] as FanID,
						 ClubID 
				  From #Customers f 
				  Where RowNum Between @RowNo and @RowNoChunk
				 ) as f
				Left Outer Join slc_report.dbo.trans t on t.fanid=f.FanID
				Left Outer Join slc_report.dbo.transactiontype tt on tt.id=t.typeid
			group by f.FanID 

		Set @RowNo = @RowNo+@ChunkSize

	--update rewards for members with no transactions
End

Create Clustered index cix_Balances_FanID on #Balances (FanID)

SELECT @msg = '#Balances Population End'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT


-----------------------------------------------------------------------------------------------------
--------------------------------------------Find out balances----------------------------------------
-----------------------------------------------------------------------------------------------------

SELECT @msg = '#WelcomeMembers Population Start'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

if object_id('tempdb..#WelcomeMembers') is not null drop table #WelcomeMembers
CREATE TABLE #WelcomeMembers (
		FanID INT NOT NULL PRIMARY KEY,
		AgreedTCsDate Datetime null,
		NewCreditCardToday BIT NULL,
		HasCreditCardBefore BIT NULL,
		NewDebitCardToday BIT NULL,
		HasDebitCardBefore BIT NULL,
		ActivatedBeforeToday BIT NULL,
		LastAddedCard DATETIME NULL,
		WelcomeCode AS 
			
			CASE 
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 1 THEN 'W7'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND HasDebitCardBefore = 1 AND ActivatedBeforeToday = 0 THEN 'W7'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 THEN 'W7'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 and 
																AgreedTCsDate >= CAST(DATEADD(dd, -2, GETDATE()) AS DATE) then 'W8'
				WHEN NewCreditCardToday = 1 AND HasCreditCardBefore = 0 AND NewDebitCardToday = 0 AND HasDebitCardBefore = 0 then 'W7'
				WHEN NewCreditCardToday = 0 AND NewDebitCardToday = 1 AND HasDebitCardBefore = 0 AND HasCreditCardBefore = 1 THEN 'W5'
			END
	)

Declare @ReportDate date = DATEADD(dd, -1, GETDATE())

INSERT INTO #WelcomeMembers(
		FanID,
		AgreedTCsDate,
		NewCreditCardToday,
		HasCreditCardBefore,
		NewDebitCardToday,
		HasDebitCardBefore,
		ActivatedBeforeToday,
		LastAddedCard)
	Select	FanID,
			AgreedTCsDate,
			Max(NewCreditCardToday) NewCreditCardToday,
			Max(HasCreditCardBefore) HasCreditCardBefore,
			Max(NewDebitCardToday)NewDebitCardToday,
			Max(HasDebitCardBefore)HasDebitCardBefore,
			Max(ActivatedBeforeToday)ActivatedBeforeToday,
			Max(AdditionDate) LastAddedCard
	From (
	SELECT 
			F.[Customer ID] AS FanID,
			f.AgreedTCsDate,			
			(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewCreditCardToday,
			(CASE WHEN PC.CardTypeID = 1 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasCreditCardBefore,
			(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) =  @ReportDate AND P.RemovalDate IS NULL THEN 1 ELSE 0 END) AS NewDebitCardToday,
			(CASE WHEN PC.CardTypeID = 2 AND CONVERT(DATE, P.AdditionDate) <  @ReportDate THEN 1 ELSE 0 END) AS HasDebitCardBefore,
			(CASE WHEN CONVERT(DATE, F.AgreedTcsDate) < @ReportDate THEN 1 ELSE 0 END) AS ActivatedBeforeToday,
			P.AdditionDate
		FROM #Customers AS F WITH (NOLOCK)
			INNER JOIN slc_report.dbo.Pan AS P WITH (NOLOCK) ON P.UserID = F.[Customer ID]
			INNER JOIN slc_report.dbo.PaymentCard AS PC WITH (NOLOCK) ON P.PaymentCardID = PC.ID
	) as a
	Group by FanID,AgreedTCsDate

SELECT @msg = '#WelcomeMembers Population End'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

-----------------------------------------------------------------------------------------------------
-------------------Populate Table of customer data as starting pint for the view---------------------
-----------------------------------------------------------------------------------------------------

SELECT @msg = 'Warehouse.SmartEmail.SmartEmail_OldSFD_CustomerData Population Started'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT

--Create Table Warehouse.SmartEmail.SmartEmail_OldSFD_CustomerData (
--			Email					nvarchar(100) not null,
--			ClubID					int not null,
--			Title					nvarchar(20) null,
--			FirstName				nvarchar(50) null,
--			Lastname				nvarchar(50) null,
--			[partial postcode]		varchar(4) null,
--			ActivationChannel		int not null,
--			RegistrationLink		nvarchar(200) null,
--			[customer id]			int not null,
--			CustomerJourneyStatus	varchar(3) not null,
--			CJS						varchar(3) not null,
--			WeekNumber				bit not null,
--			IsRegistered			bit not null,
--			AgreedTcsDate			datetime not null,
--			dob						date not null,
--			ClubCashPending			SmallMoney not null,
--			ClubCashAvailable		SmallMoney not null,
--			LastAddedCard			Date null,
--			WelcomeCode				varchar(2) null--,
--			Primary Key	([customer id])
--			) 

Declare @RowCount int
Truncate Table SmartEmail.SmartEmail_OldSFD_CustomerData

Insert into SmartEmail.SmartEmail_OldSFD_CustomerData
Select	c.Email,
		c.ClubID,
		c.Title,
		c.FirstName,
		c.Lastname,
		c.[partial postcode],
		c.ActivationChannel,
		c.RegistrationLink,
		c.[Customer ID],
		'SSN' as CustomerJourneyStatus,
		'SAV' as CJS,
		0 as WeekNumber,
		IsRegistered,
		c.AgreedTCsDate,
		c.dob,
		coalesce(b.ClubCashPending,0) AS ClubCashPending,
		Coalesce(b.ClubCashAvailable,0)ClubCashAvailable,
		w.LastAddedCard,
		w.WelcomeCode
From #Customers as c
inner join #Balances as b
	on c.[Customer ID] = b.FanID
left Outer Join #WelcomeMembers as w
	on b.FanID = w.FanID
Set @RowCount = @@ROWCOUNT

SELECT @msg = 'Warehouse.SmartEmail.SmartEmail_OldSFD_CustomerData Population End'
	EXEC Staging.oo_TimerMessage @msg, @time OUTPUT


/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  staging.JobLog_Temp
Set		EndDate = GETDATE(),
		TableRowCount = @ROWCOUNT
where	StoredProcedureName = 'Staging.SLC_Report_DailyLoad_CustomerData' and
		TableSchemaName = 'SmartEmail' and
		TableName = 'SmartEmail_OldSFD_CustomerData' and
		EndDate is null

/*--------------------------------------------------------------------------------------------------
---------------------------------------  Update JobLog Table ---------------------------------------
----------------------------------------------------------------------------------------------------*/
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