CREATE Procedure [Staging].[PennyforLondon_Customer]
WITH EXECUTE AS OWNER
as
Begin

/*--------------------------------------------------------------------------------------------------
----------------------Create Table of Customers who's AgreedTCs was removed------------------------
----------------------------------------------------------------------------------------------------*/

--if object_id('tempdb..#PrevAct') is not null drop table #PrevAct
--select FANID,Min(Value) as AgreedTCs
--into #PrevAct
--from archive.ChangeLog.DataChangeHistory_Datetime as dt
--inner join archive.ChangeLog.TableColumns as tc
--	on dt.TableColumnsID = tc.ID
--inner join SLC_Report.dbo.Fan as f
--	on dt.FanID = f.ID
--Where ColumnName = 'AgreedTCsDate' and 
--	  not(Value is NULL) 
--	  and (f.AgreedTCsDate is null or f.AgreedTCs = 0) and ClubID in (141)
--Group by FanID

/*--------------------------------------------------------------------------------------------------
-----------------------------Write entry to JobLog Table--------------------------------------------
----------------------------------------------------------------------------------------------------*/

Insert into Relational.JobLog_Temp
Select	StoredProcedureName = 'Penny4London_Customer',
		TableSchemaName = 'Relational',
		TableName = 'Customer',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = 'R'

TRUNCATE TABLE Relational.Customer
--------------------------------------------------------------------------
---------------Insert Main Data in Staging.Customer Table-----------------
--------------------------------------------------------------------------
DROP INDEX Relational.Customer.IX_Customer_CompositeID
DROP INDEX Relational.Customer.IX_Customer_SourceUID

INSERT INTO Relational.Customer
select	f.ID													 as FanID,
		cast(f.SourceUID as varchar(20))						 as SourceUID,    --this links to CIN in the data from RBS
		cast(f.CompositeID as bigint)							 as CompositeID,
		Case
			When f.AgreedTCs = 0 then 0
			When f.AgreedTCsDate is null then 0
			Else f.Status
		End									 			 		 as [Status],
		Cast(Case
				When f.Sex = 1 then 'M'
				When f.Sex = 2 then 'F'
				Else 'U'
			 End as CHAR(1)) as Gender,
		cast(f.Title as varchar(20))							 as Title,
		cast(f.FirstName as varchar(50))						 as FirstName,
		cast(f.LastName as varchar(50))							 as LastName,
		Cast(Case
				When Len(replace(f.Title,' ',''))>1 then 'Dear '+f.Title+' '+f.LastName
				When (Len(replace(f.Title,' ',''))<=1 or f.Title is null) and f.sex = 1 then 'Dear Mr '+f.LastName
				Else Null
			 End as varchar(100)) as Salutation,
		cast(f.Address1 as varchar(100))						 as Address1,
		cast(f.Address2 as varchar(100))						 as Address2,
		cast(f.City as varchar(100))							 as City,
		cast(f.County as varchar(100))							 as County,
		isnull(ltrim(rtrim(cast(f.Postcode as varchar(10)))),'') as PostCode,
		NULL as PostalSector,
			Cast(case 
				When f.Postcode IS null then ''
				when charindex(' ', f.PostCode) = 0 then cast(f.PostCode as varchar(4))
				else left(f.PostCode, charindex(' ', f.PostCode) - 1) 
			 end as  Varchar(4))				as PostCodeDistrict,
		Cast(Case 
				When f.Postcode IS null then ''
				when f.PostCode like '[A-Z][0-9]%' then left(f.PostCode,1) 
				else left(f.PostCode,2) 
			 end as Varchar(2)) 								 as PostArea,
		Cast(Null as varchar(30))								 as Region,
		cast(f.email as varchar(100))							 as Email,
		Case
			When f.unsubscribed is null then 0
			When Cast(f.Unsubscribed as bit) = 1 then 1
			Else 0
		End														 as Unsubscribed,
		Case
			When f.HardBounced is null then 0
			When cast(f.HardBounced as bit) = 1 then 1
			Else 0
		End														 as Hardbounced,
		Cast(case 
				when f.Email like '%@%.%' and f.Email not like '%@%.'			
					 and f.Email not like '@%.%' and f.Email not like '@.%'		
					and f.Email not like '%@%@%' and f.Email not like '%[:-?]%' 
					and f.Email not like '%,%' and ltrim(rtrim(f.Email)) Not like '% %' 
					and LEN(ltrim(rtrim(f.email))) >= 9 then 1 
				else 0 
			 end as bit)						as EmailStructureValid,
		f.MobileTelephone						as MobileTelephone,
		Cast(Case
				When (	left(replace(f.MobileTelephone,' ',''),2) like '07' or
						LEFT(replace(f.MobileTelephone,' ',''),4) like '+447'
					 )  and LEN(replace(f.MobileTelephone,' ','')) >= 11 Then 1
				Else 0
			 End as bit) as ValidMobile,
		1 as Activated,
		cast(/*Coalesce(pa.AgreedTCs,*/f.AgreedTCsDate/*)*/ as date)	 as ActivatedDate,
		Case 
			When f.Status = 0 then 0
			When f.AgreedTCs = 0 then 0
			When Len(f.Postcode) < 3 then 0
			Else Cast(Null as bit)					
		End										as MarketableByEmail,
		f.dob	as DOB,
		Case
			When datediff(year,dob,Getdate()) > 150 then null
			Else
				Cast(case	
						When f.dob > CAST(getdate() as DATE) then 0
						when month(f.DOB)>month(getdate()) then datediff(yyyy,f.DOB,getdate())-1 
						when month(f.DOB)<month(getdate()) then datediff(yyyy,f.DOB,getdate()) 
						when month(f.DOB)=month(getdate()) then 
								case when day(f.DOB)>day(getdate()) then datediff(yyyy,f.DOB,getdate())-1 
									 else datediff(yyyy,f.DOB,getdate()) 
								end 
					 end as tinyint)
		End as AgeCurrent,
		Cast(Null as tinyint)					as AgeCurrentBandNumber,
		Cast(NULL as Varchar(10))				as AgeCurrentBandText,
		f.ClubID,
		/*Case --******To Be Fixed
			When f.Status = 0 or f.AgreedTCs = 0 or f.AgreedTCsDate is null then ca.DeactivatedDate
			Else NULL
		End*/ NULL as DeactivatedDate,
		/*Case--******To Be Fixed
			When f.Status = 0 or f.AgreedTCs = 0 or f.AgreedTCsDate is null then ca.OptedOutDate
			Else NULL
		End*/ Null as OptedOutDate,
		Cast(Null as bit)					as CurrentlyActive
from	SLC_Report.dbo.Fan f
Left Outer join Staging.Customer_WarehouseExclusions as e
	on f.ID = e.FanID
/******
Left outer join #PrevAct as pa
	on	f.ID = pa.FanID
 ******/
where	--(f.AgreedTCs = 1 /****or Not(pa.AgreedTCs IS null)****/) and
		f.ClubID in (141) and e.FanID is null


--------------------------------------------------------------------------
-------------------------Enchance Customer Data Part 1--------------------
--------------------------------------------------------------------------
update Relational.Customer 
set		PostalSector =	
		Case
			When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]' Then
				 Left(replace(replace(PostCode,char(160),''),' ',''),2)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),3),1)
			When replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]' or
				 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]' or 
				 replace(replace(PostCode,char(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]' Then 
				 Left(replace(replace(PostCode,char(160),''),' ',''),3)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),4),1)
			When replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' or
				 replace(replace(PostCode,char(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'Then 
				 Left(replace(replace(PostCode,char(160),''),' ',''),4)+' '+Right(Left(replace(replace(PostCode,char(160),''),' ',''),5),1)
			Else ''
		End,
		Region = pa.Region,
		AgeCurrentBandNumber =
			case 
				when AgeCurrent is null then 0
				when not AgeCurrent between 18 and 110 then 0
				when AgeCurrent between 18 and 24 then 1
				when AgeCurrent between 25 and 34 then 2
				when AgeCurrent between 35 and 44 then 3
				when AgeCurrent between 45 and 54 then 4
				when AgeCurrent between 55 and 64 then 5
				when AgeCurrent between 65 and 80 then 6
				when AgeCurrent between 81 and 110 then 7
			end
from Relational.Customer as c
Left Outer Join Relational.PostArea  as pa
		on (case 
				when c.PostCode like '[A-Z][0-9]%' then left(c.PostCode,1) 
				else left(c.PostCode,2) 
			end) = pa.PostAreaCode
	
--------------------------------------------------------------------------
-------------------------Enchance Customer Data Part 3--------------------
--------------------------------------------------------------------------
update Relational.Customer
set		AgeCurrentBandText =
			case 
				when AgeCurrentBandNumber = 0 then 'Unknown'
				when AgeCurrentBandNumber = 1 then '18 to 24'
				when AgeCurrentBandNumber = 2 then '25 to 34'
				when AgeCurrentBandNumber = 3 then '35 to 44'
				when AgeCurrentBandNumber = 4 then '45 to 54'
				when AgeCurrentBandNumber = 5 then '55 to 64'
				when AgeCurrentBandNumber = 6 then '65 to 80'
				when AgeCurrentBandNumber = 7 then '81+'
			end,
		MarketableByEmail =
			case 
				when ActivatedDate is not null
					 and Status > 0						--account is active. This field will be set to 0 is customer is deceased. Discussed with Tracy 9 March 2012
					 and Unsubscribed = 0				--customer has not unsubscribed. Joe + Niru to start updating this field from SFD (discussed 15 March 2012)
					 and Hardbounced = 0					--email address has not hardbounced.
					 and EmailStructureValid = 1			--result of basic structutral validation above
					 and MarketableByEmail is null
					 then 1
				else 0 
			end,
		CurrentlyActive = 
			CASE
				WHEN	DeactivatedDate IS NULL
					AND OptedOutDate IS NULL
					AND Status = 1
					AND ActivatedDate <= CAST(GETDATE() AS DATE)
					THEN 1
				ELSE 0
			END

CREATE NONCLUSTERED INDEX IX_Customer_CompositeID ON Relational.Customer (FanID)
CREATE NONCLUSTERED INDEX IX_Customer_SourceUID ON Relational.Customer (SourceUID)

/*--------------------------------------------------------------------------------------------------
---------------------------Update entry in JobLog Table with End Date-------------------------------
----------------------------------------------------------------------------------------------------*/
Update  Relational.JobLog_Temp
Set		EndDate = GETDATE()
where	StoredProcedureName = 'Penny4London_Customer' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer' and
		EndDate is null
/*--------------------------------------------------------------------------------------------------
-----------------------------Update entry in JobLog Table with Row Count------------------------------
------------------------------------------------------------------------------------------------------*/
--Count run seperately as when table grows this as a task on its own may take several minutes and we do
--not want it included in table creation times
Update  Relational.JobLog_Temp
Set		TableRowCount = (Select COUNT(*) from Relational.Customer)
where	StoredProcedureName = 'Penny4London_Customer' and
		TableSchemaName = 'Relational' and
		TableName = 'Customer' and
		TableRowCount is null


Insert into Relational.JobLog
select	[StoredProcedureName],
		[TableSchemaName],
		[TableName],
		[StartDate],
		[EndDate],
		[TableRowCount],
		[AppendReload]
from Relational.JobLog_Temp

truncate table Relational.JobLog_Temp

End