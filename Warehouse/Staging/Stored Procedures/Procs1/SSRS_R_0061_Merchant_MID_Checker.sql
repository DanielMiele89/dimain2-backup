CREATE Procedure Staging.SSRS_R_0061_Merchant_MID_Checker (@MIDs varchar(150))
as 
Declare /*@MIDs varchar(150),*/
		@FormattedMIDs varchar(200),
		@Qry nvarchar(max)
--Set @MIDs = '98666813,12345657'

Set @FormattedMIDs = Replace(@MIDs,',',CHAR(39)+','+CHAR(39))
--Select  @MIDs,@FormattedMIDs
if object_id('Staging.R_0061_Merchant_MID_Checker') is not null drop table Staging.R_0061_Merchant_MID_Checker
Set @Qry = '
Select	cc.MID,
		cc.ConsumerCombinationID,
		cc.Narrative,
		cc.LocationCountry,
		MIN(ct.TranDate) as FirstTran,
		MAX(ct.TranDate) as LastTran,
		COUNT(*) as Trans,
		Max(Case
				When CardholderPresentData = 5 then 1
				Else 0
			End) as OnlineTrans,
		Max(Case
				When CardholderPresentData <> 5 then 1
				Else 0
			End) as OfflineTrans
Into Staging.R_0061_Merchant_MID_Checker
From
	(Select	MID,
			ConsumerCombinationID,
			Narrative,
			LocationCountry
	
	 From	Warehouse.relational.ConsumerCombination as cc
	 Where MID in ('''+@FormattedMIDs+''')
	) as cc
Left Outer join warehouse.relational.ConsumerTransaction as ct
	on cc.ConsumerCombinationID = ct.ConsumerCombinationID
Group By cc.MID,cc.ConsumerCombinationID,cc.Narrative,cc.LocationCountry
'

Exec Sp_ExecuteSQL @Qry

Select * from Staging.R_0061_Merchant_MID_Checker