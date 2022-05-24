CREATE Procedure [Staging].[RedemptionMemberSubmission] (@TableName varchar(150))
With Execute as Owner
As

Declare @TName varchar(150),
		@Qry nvarchar(max),
		@Errors int

Set @TName = @TableName
Set @Errors = 0

--------------------------------------------------------------------------------------------------
-------------------Truncate Staging table used to hold new redemption memberships-----------------
--------------------------------------------------------------------------------------------------

Truncate Table Staging.RedemptionMemberships_Temp

--------------------------------------------------------------------------------------------------
--------------------------------Take data provided and insert into Staging table------------------
--------------------------------------------------------------------------------------------------

Set @Qry = '
	Insert Into Staging.[RedemptionMemberships_Temp]
	Select	RedeemID,
			CompositeID,
			Cast(StartDate as Datetime) as [StartDate],
			CasT(EndDate as Datetime) as [EndDate]
	from ' + @TName

Exec SP_ExecuteSQL @Qry

--------------------------------------------------------------------------------------------------
------------------------------------Check to see if the data looks OK-----------------------------
--------------------------------------------------------------------------------------------------

--Check1	-- does the redemption exist
			-- dates are not errors
			-- Customer is active

Select Case
			When r.id is null then 'Non existant Redemption'
			When t.StartDate < Getdate() then 'StartDate In The Past'
			When t.EndDate < Getdate() then 'EndDate In The Past'
			When t.EndDate < t.StartDate then 'EndDate Earlier than StartDate'
			When c.FanID is null or c.CurrentlyActive <> 1 then 'Customer is not active'
			Else 'Fine'
		End as [Problem],
		t.RedeemID,t.StartDate,t.EndDate,Count(*) as [rows]
Into #FirstChecks
From Staging.RedemptionMemberships_Temp as t
Left Outer join slc_report.dbo.Redeem as r
	on t.redeemid = r.id
Left Outer join Relational.Customer as c
	on t.CompositeID = c.CompositeID
--Where	r.id is null or (t.EndDate > getdate())
Group by Case
			When r.id is null then 'Non existant Redemption'
			When t.StartDate < Getdate() then 'StartDate In The Past'
			When t.EndDate < Getdate() then 'EndDate In The Past'
			When t.EndDate < t.StartDate then 'EndDate Earlier than StartDate'
			When c.FanID is null or c.CurrentlyActive <> 1 then 'Customer is not active'
			Else 'Fine'
		End,
		RedeemID,t.StartDate,t.EndDate
--Union All

--

Set @Errors = (Select Count(*) as Errors From #FirstChecks as f Where [Problem] <> 'Fine')

Set @Errors = @Errors + (	Select Count(*) as Errors
							from Zion.NominatedRedeemMember as Z
							inner join Staging.RedemptionMemberships_Temp as t
									on	z.CompositeID = t.CompositeID and
							z.RedeemID = t.RedeemID
						)

Set @Errors = @Errors + 
						(Select Count(*)
						 From 
							(	Select CompositeID,RedeemID
								From Staging.RedemptionMemberships_Temp as a
								Group by CompositeID,RedeemID
									Having Count(*) > 1
							) as a
						)
--Select @Errors

IF @Errors = 0
Begin
	Insert into Zion.NominatedRedeemMember
	Select	RedeemID,
			CompositeID,
			StartDate,
			EndDate,
			Getdate() as [Date]
	From Staging.RedemptionMemberships_Temp

	Select 'Rows Added to Zion.NominatedRedeemMember'
End 

IF @Errors > 0
Begin
	Select [Problem]--,Count(*) as Problems
	From #FirstChecks
	Where [Problem] <> 'Fine'
	Group by [Problem]
	Union All
	Select Distinct 'Members Already Added'--,
			--Count(*)
	from Zion.NominatedRedeemMember as Z
	inner join Staging.RedemptionMemberships_Temp as t
			on	z.CompositeID = t.CompositeID and
				z.RedeemID = t.RedeemID
	Union All
	Select Distinct 'Duplicate Rows in Data'
						 From 
							(	Select CompositeID,RedeemID
								From Staging.RedemptionMemberships_Temp as a
								Group by CompositeID,RedeemID
									Having Count(*) > 1
							) as a

End