/*
-- Replaces this bunch of stored procedures:
EXEC WHB.LoyaltyAdditions_Customer_MarketableByEmailStatus_MI
EXEC WHB.LoyaltyAdditions_Customer_Registered_MI_V1_1
EXEC WHB.LoyaltyAdditions_DirectDebit_OINs
EXEC WHB.LoyaltyAdditions_DirectDebitOriginator
EXEC WHB.LoyaltyAdditions_Customer_RBSGSegments_V3
EXEC WHB.LoyaltyAdditions_Customer_SchemeMembership_V1_1
EXEC WHB.LoyaltyAdditions_CustomerNominee

*/
CREATE PROCEDURE [WHB].[__LoyaltyAdditions_Daily_Archived] 
AS 

SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


DECLARE @msg VARCHAR(200), @RowsAffected INT



-------------------------------------------------------------------------------
-- LoyaltyAdditions_Customer_MarketableByEmailStatus_MI #######################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_MarketableByEmailStatus_MI', 'Starting'

CREATE TABLE #Cust (FanID int, MarketableByEmail tinyint, Primary Key (FanID))

INSERT INTO #Cust
SELECT FanID,
	Case
		When CurrentlyActive = 0 then 3
		When MarketableByEmail = 1 then 1
		When Hardbounced = 1 then 3
		When EmailStructureValid = 0 then 3
	Else 2
	End as MarketableByEmail
FROM Derived.Customer as c


--End Date old Entries
UPDATE m
SET EndDate = dateadd(day,-1,Cast(getdate()as date))
FROM Derived.Customer_MarketableByEmailStatus_MI m
INNER JOIN #Cust c
	ON m.fanid = c.fanid 
	and m.EndDate is null 
	and m.MarketableID <> c.MarketableByEmail


--Create New Entries
INSERT INTO Derived.Customer_MarketableByEmailStatus_MI
SELECT	c.FanID,
		c.MarketableByEmail,
		StartDate = Cast(getdate() as date),
		EndDate = Cast(Null as date)
FROM #Cust as c
WHERE NOT EXISTS (SELECT 1 FROM Derived.Customer_MarketableByEmailStatus_MI m
	WHERE c.fanid = m.fanid 
	AND m.EndDate is null 
	AND m.MarketableID = c.MarketableByEmail)

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_MarketableByEmailStatus_MI', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_Customer_Registered_MI_V1_1 ###############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_Registered_MI_V1_1', 'Starting'

--End Date old Entries
UPDATE m
	SET EndDate = dateadd(day,-1,Cast(getdate()as date))
FROM Derived.Customer_Registered m	
INNER JOIN Derived.Customer c	
	ON c.fanid = m.fanid 
	and m.EndDate is null 
	and m.Registered <> c.Registered

--Create New Entries
INSERT INTO Derived.Customer_Registered (FanID, Registered, StartDate, EndDate)
SELECT	c.FanID,
		c.Registered,
		StartDate = Cast(getdate()as date),
		EndDate = Cast(Null as date)
FROM Derived.Customer c
WHERE NOT EXISTS (SELECT 1 FROM Derived.Customer_Registered m
	WHERE c.fanid = m.fanid 
	and m.EndDate is null 
	and m.Registered = c.Registered)

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_Registered_MI_V1_1', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_DirectDebit_OINs ##########################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_DirectDebit_OINs', 'Starting'

ALTER INDEX  ix_DirectDebit_OINs_OIN ON Derived.DirectDebit_OINs DISABLE

--Insert UN-NORMALISED version of data
Truncate Table Derived.DirectDebit_OINs
Insert into Derived.DirectDebit_OINs
Select	d.ID,
		d.OIN,
		d.Narrative,
		s.Status_Description,
		a.Reason_Description,
		AddedDate,
		i.Category1 as InternalCategory1,
		i.category2 as InternalCategory2,
		r.Category1 as RBSCategory1,
		r.Category2 as RBSCategory2,
		d.StartDate as StartDate,
		d.EndDate as EndDate,
		sup.SupplierID,
		sup.SupplierName
From Staging.DirectDebit_OINs as d

Inner join Staging.DirectDebit_Status as s
	on d.DirectDebit_StatusID = s.ID

inner join Staging.DirectDebit_AssessmentReason as a
	on d.DirectDebit_AssessmentReasonID = a.ID

Left join Staging.DirectDebit_Categories_Internal as i
	on d.InternalCategoryID = i.id

Left join Staging.DirectDebit_Categories_RBS as r
	on d.RBSCategoryID = r.id

Left join Relational.DD_DataDictionary_Suppliers as sup
	on d.DirectDebit_SupplierID = sup.SupplierID

ALTER index ix_DirectDebit_OINs_OIN on Derived.DirectDebit_OINs REBUILD



Truncate Table [Staging].[DirectDebit_EligibleOINs]
Insert into [Staging].[DirectDebit_EligibleOINs]
Select	OIN,
		Case
			When RBSCategory1 = 'Household Bills' then 'Household'
			Else RBSCategory1
		end as RBSCategory1,
		RBSCategory2,
		SupplierName,
		StartDate
from Derived.DirectDebit_OINs as r 
Where [Status_Description] = 'Accepted by RBSG' 
and EndDate is NULL

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_DirectDebit_OINs', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_DirectDebitOriginator #####################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_DirectDebitOriginator', 'Starting'

TRUNCATE TABLE Derived.[DirectDebitOriginator]

INSERT INTO Derived.[DirectDebitOriginator]
SELECT	do.ID,
		do.Oin,
		do.Name as SupplierName,
		c1.Name as Category1,
		Case
			When a.Oin is not null then 'Water'
			Else c2.Name
		End as Category2,
		do.StartDate,
		do.EndDate
FROM SLC_Report.dbo.DirectDebitOriginator do
LEFT JOIN SLC_Report.dbo.DirectDebitCategory1 c1
	on do.Category1ID = c1.ID
LEFT JOIN SLC_Report.dbo.DirectDebitCategory2 c2
	on do.Category2ID = c2.ID
LEFT JOIN (	
	SELECT DISTINCT OIN
	FROM Derived.DirectDebit_OINs
	WHERE InternalCategory2 = 'Utilities' 
	and RBSCategory2 = 'Local Authority and Water'
) a
	ON do.OIN = a.oin

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_DirectDebitOriginator', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_Customer_RBSGSegments_V3 ##################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_RBSGSegments_V3', 'Starting'

DECLARE @LaunchDate as Date  = '2015-07-20'

if object_id('tempdb..#CS') is not null drop table #CS;
SELECT
	a.FanID,
	a.CustomerSegment,
	a.StartDate,
	a.RowNo
INTO #CS
FROM (	
	SELECT	
		c.FanID,
		Case
			When ica.Value is null then ''
			When ica.Value = 'V' then 'V'
			Else ''
		End as CustomerSegment,
		Case
			when ica.IssuerCustomerID is null and ActivatedDate >= @LaunchDate then ActivatedDate
			when ica.IssuerCustomerID is null then @LaunchDate
			When ica.StartDate < @Launchdate then @LaunchDate
			Else ica.StartDate
		End as StartDate,
		ROW_NUMBER() OVER(PARTITION BY c.FanID ORDER BY ica.Value DESC) AS RowNo
	FROM Derived.Customer c
	left join SLC_Report.dbo.IssuerCustomer as ic
		on c.SourceUID = ic.SourceUID
	Left join slc_report.dbo.issuer as i
		on ic.IssuerID = i.ID
	Left join slc_report.dbo.IssuerCustomerAttribute as ica
		on ic.ID = ica.IssuerCustomerID and
			ica.EndDate is null and ica.AttributeID = 1
	WHERE	((c.ClubID = 138 and i.ID = 1) Or (c.ClubID = 132 and i.ID = 2) or i.id is null) 
		and EndDate is null
)  a
WHERE a.RowNo = 1
-- (4388857 rows affected)


--Insert new segments----------------------------------------
INSERT INTO Derived.Customer_RBSGSegments
SELECT	c.FanID,
		c.CustomerSegment,
		c.StartDate,
		NULL as EndDate
FROM #CS c
WHERE NOT EXISTS (
	SELECT 1 
	FROM Derived.Customer_RBSGSegments as cs
	WHERE c.fanid = cs.fanid 
	and cs.enddate is null 
	and (Case
			When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
			Else c.CustomerSegment
			End) =
		(Case
				When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
				Else cs.CustomerSegment
			End)
)


--Update old segments----------------------------------------
UPDATE cs
SET EndDate = dateadd(day,-1,c.StartDate)
FROM Derived.Customer_RBSGSegments cs
INNER JOIN #CS as c
	ON cs.fanid = c.fanid 
	and cs.enddate is null 
	and (Case
			When c.CustomerSegment <> 'V' or c.CustomerSegment is null then ''
			Else c.CustomerSegment
			End) <>
		(Case
				When cs.CustomerSegment <> 'V' or cs.CustomerSegment is null then ''
				Else cs.CustomerSegment
			End)

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_RBSGSegments_V3', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_Customer_SchemeMembership_V1_1 ############################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_SchemeMembership_V1_1', 'Starting'

--Find each customers Scheme Membership type
if object_id('tempdb..#SMT') is not null drop table #SMT
Select	c.FanID,
		Case
			When c.CurrentlyActive = 0 then 8
			When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (2) then 1
			When dd.OnTrial = 1 and cp.PaymentMethodsAvailableID IN (0) then 3
			When dd.OnTrial = 1 then 3
			When cp.PaymentMethodsAvailableID in (0) then 4
			When cp.PaymentMethodsAvailableID in (1) then 5
			When cp.PaymentMethodsAvailableID in (2) then 2
			When cp.PaymentMethodsAvailableID in (3) then 4
			Else null
		End as SchemeMembershipTypeID,
		ActivatedDate,
		DeactivatedDate
Into #SMT
From Derived.Customer c
inner join Derived.CustomerPaymentMethodsAvailable cp
	on c.FanID = cp.FanID 
	and cp.EndDate is null
left join SLC_Report.[dbo].[FanSFDDailyUploadData_DirectDebit] dd
	on c.FanID = dd.FanID

CREATE CLUSTERED INDEX cs_Stuff ON #SMT (FanID)


UPDATE b
	SET SchemeMembershipTypeID = 
			(Case
				When b.SchemeMembershipTypeID in (1,2,5) then 6
				When b.SchemeMembershipTypeID in (3,4) then 7
				Else b.SchemeMembershipTypeID
				End)
				
FROM #SMT b
INNER JOIN Staging.SLC_Report_DailyLoad_Phase2DataFields a
	on b.FanID = a.FanID
WHERE a.LoyaltyAccount = 1 
	and b.SchemeMembershipTypeID in (1,2,3,4,5)


--Close off existing records in Relational.Customer_SchemeMembership
UPDATE cs
	SET EndDate = Case
					When DeactivatedDate = Cast(getdate() as date) then Dateadd(day,-1,CAST(getdate() as Date))
					Else Dateadd(day,-2,CAST(getdate() as Date))
				End
FROM Derived.Customer_SchemeMembership as cs	
INNER JOIN #SMT as smt	
	on smt.FanID = cs.FanID
WHERE smt.SchemeMembershipTypeID <> cs.SchemeMembershipTypeID 
	and cs.EndDate is null


--Create new entries in Relational.Customer_SchemeMembership-----------------------
INSERT INTO Derived.Customer_SchemeMembership
SELECT	smt.FanID,
		smt.SchemeMembershipTypeID,
		Case
			When ActivatedDate = CAST(getdate() as Date) then CAST(getdate() as Date)
			Else dateadd(day,-1,CAST(getdate() as Date))
		End as StartDate,
		CAST(NULL as Date) as EndDate
FROM #SMT as smt
WHERE NOT EXISTS (SELECT 1 FROM Derived.Customer_SchemeMembership as cs
	WHERE smt.FanID = cs.FanID 
		and smt.SchemeMembershipTypeID = cs.SchemeMembershipTypeID 
		and cs.EndDate is null)

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_Customer_SchemeMembership_V1_1', 'Finished'




-------------------------------------------------------------------------------
-- LoyaltyAdditions_CustomerNominee ###########################################
-------------------------------------------------------------------------------
EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_CustomerNominee', 'Starting'

if object_id('tempdb..#Nominee') is not null drop table #Nominee
SELECT DISTINCT 
	c.FanID,
	Case
		When	dd.FanID is null then 0
		When	dd.Nominee = 1 and (a.LoyaltyAccount = 1 or dd.OnTrial = 1) then 1
		Else 0
	End Nominee,
	c.ActivatedDate
INTO #Nominee
FROM Derived.Customer c
LEFT JOIN Staging.SLC_Report_DailyLoad_Phase2DataFields a
	on c.FanID = a.FanID 
	and a.LoyaltyAccount = 1
LEFT JOIN SLC_Report.[dbo].[FanSFDDailyUploadData_DirectDebit] dd
	on	c.FanID = dd.FanID 
	and dd.Nominee = 1 
	and c.CurrentlyActive = 1

CREATE CLUSTERED INDEX cx_Stuff ON #Nominee (FanID, Nominee)
	

--Add new entries for change in nominee status
INSERT INTO Derived.Customer_Loyalty_DD_Nominee
SELECT	n.FanID,
		n.Nominee,
		Case
			When ActivatedDate = Cast(getdate() as date) then Cast(getdate() as date)
			Else Dateadd(day,-1,getdate())
		End as StartDate,
		CAST(NULL as DATE) as EndDate
FROM #Nominee n
WHERE NOT EXISTS (SELECT 1 FROM Derived.Customer_Loyalty_DD_Nominee d
	WHERE n.FanID = d.FanID 
	and n.Nominee = d.Nominee 
	and d.EndDate is null)

	
--Update old entries for Nominees	
UPDATE d
	SET EndDate = Case
		When ActivatedDate = Cast(getdate() as date) then Dateadd(day,-1,Cast(getdate() as date))
		Else Dateadd(day,-2,Cast(GETDATE() as DATE))
	End
FROM Derived.Customer_Loyalty_DD_Nominee d
INNER JOIN #Nominee n
	on n.FanID = d.FanID 
	and n.Nominee <> d.Nominee 
	and EndDate is null

EXEC Monitor.ProcessLog_Insert 'WHB', 'LoyaltyAdditions_CustomerNominee', 'Finished'



RETURN 0