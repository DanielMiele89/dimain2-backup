--Use Warehouse
CREATE Procedure Staging.WarehouseLoad_CustomerMatchingTable 
				@TableName varchar(300),
				@Field varchar(30),
				@PartnerID Varchar(5),
				@MatchDate varchar(10)

As
Begin

Declare @Qry nvarchar(max)

Select @MatchDate

Set @Qry = '


Insert into [Relational].[Customer_MerchantDataMatching]
Select Distinct '+@PartnerID+' as PartnerID, '+@Field+' as FanID,'''+@MatchDate+''' as MatchDate
From '+@TableName

--Select @Qry

Exec sp_ExecuteSQL @Qry 

Set @Qry = 'Drop table '+ @TableName

Exec sp_ExecuteSQL @Qry

End


--select FanID,
--From Sandbox.Stuart.SpaceNK_HashedDataMatches_20150407