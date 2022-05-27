CREATE Procedure [Staging].[SSRS_R0079_PrelaunchCheck_MIDsAlreadyInGaswithoutAddress] 
			@TableName varchar(250),
			@MID_Name varchar(20)
as

-----------------------------------------------------------------------------------------------
----------------------------Create a table to put MIDs list in---------------------------------
-----------------------------------------------------------------------------------------------

if object_id('Staging.MIDs_TempTable') is not null drop table Staging.MIDs_TempTable
Create Table Staging.MIDs_TempTable (
				MerchantID varchar(30),
				Address1 varchar(150),
				Address2 varchar(150),
				City varchar(100),
				Postcode varchar(10),
				Original bit,
				RowNo int,
				Primary Key (MerchantID))

-----------------------------------------------------------------------------------------------
-----------------------Populate with list of MIDs supplied by Merchant-------------------------
-----------------------------------------------------------------------------------------------
Declare	@Qry nvarchar(max)

--Set @TableName = 'Sandbox.[Stuart].[LauraAshleyMIDs_20150527]'
--Set @Mid_Name = 'MIDs'
Set @Qry = '
Insert into Staging.MIDs_TempTable
Select '+@MID_Name+' as MerchantID,
		Left(Address1,150) as Address1,
		Left(Address2,150) as Address2,
		Left(City,100) as City,
		Left(Postcode,10) as Postcode,
		1 as Original,
		ROW_NUMBER() OVER(ORDER BY '+@MID_Name+' DESC) AS RowNo
from '+@TableName+'
Where Len('+@MID_Name+') > 3'

Exec sp_executeSQL @Qry

--Select [MerchantID] from [Staging].[MIDs_TempTable] 
Update [Staging].[MIDs_TempTable] 
Set MerchantID = Replace(MerchantID,' ','')
-----------------------------------------------------------------------------------------------
---------Populate with list of preceding/non preceding zero MIDs supplied by Merchant----------
-----------------------------------------------------------------------------------------------

Insert into Staging.MIDs_TempTable
Select Case
			When Left(a.MerchantID,1) = '0' then Right(a.MerchantID,(Len(a.MerchantID)-1))
			Else '0'+a.MerchantID
	   End as MID,
		Left(Address1,150) as Address1,
		Left(Address2,150) as Address2,
		Left(City,100) as City,
		Left(Postcode,10) as Postcode,
	   0 as Original,
	   RowNo
from Staging.MIDs_TempTable as a

-----------------------------------------------------------------------------------------------
---------------------------Check if any of these MIDs are in GAS already-----------------------
-----------------------------------------------------------------------------------------------

Select	'Address Already in Gas' as [Assessment Type],
		ro.ID as OutletID,
		ro.MerchantID,
		f.Address1,
		f.Address2,
		f.City,
		f.Postcode,
		p.ID as PartnerID,
		p.Name as PartnerName,
		a.Address1 as Merchant_Address1,
		a.Address2 as Merchant_Address2,
		a.City as Merchant_City,
		a.Postcode as Merchant_Postcode
from Staging.MIDs_TempTable as a
inner join slc_report.dbo.RetailOutlet as ro
	on a.MerchantID = ro.MerchantID
inner join slc_report..Fan as f
	on ro.fanid = f.id
inner join SLC_Report..[Partner] as p
	on ro.Partnerid = p.id
Where	f.Address1 is null or 
		len(f.Address1) < 2 or
		ro.GeolocationUpdateFailed = 1 or
		Len(f.city) < 3 or
		f.city is null