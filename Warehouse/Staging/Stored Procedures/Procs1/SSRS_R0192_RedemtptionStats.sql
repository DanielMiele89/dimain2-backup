

CREATE PROCEDURE [Staging].[SSRS_R0192_RedemtptionStats] (@StartDate datetime, @EndDate datetime)
AS
Begin

		Declare @EndDateCalc datetime = dateadd( ss, -1, dateadd(d, 1, @Enddate));

		WITH RL (ItemID, ClubCash, Date, Counter) AS
		(
			select itemid, clubcash, date, 1
			from SLC_Repl..trans t
			where date between @StartDate and @EndDateCalc
			and typeid = 3
			UNION ALL
			select tr.itemid, -t.clubcash, t.date, -1
			from SLC_REPL..trans t
			inner join SLC_REPL..trans tr on t.itemID = tr.ID
			where t.date between @StartDate and @EndDateCalc
			and t.typeid = 4
			and tr.typeID = 3
		)
		select 	case when ri.RedeemID in (7111, 7176) then 'Cash Back'
			    when ri.RedeemID in (7178, 7179) then 'Pay to Credit'
			    else ri.RedeemType END as RedeemType,
	            t.itemid, r.description, SUM(Counter) as Total, SUM(ClubCash) as TotalClubCash, MIN(Date) as FirstDate, MAX(Date) as LastDate
		from RL t
		left join SLC_REPL..Redeem r 
			on t.ItemID = r.ID
		left join Warehouse.Relational.RedemptionItem ri 
			on ri.RedeemID = t.ItemID
		group by (case when ri.RedeemID in (7111, 7176) then 'Cash Back'
			    when ri.RedeemID in (7178, 7179) then 'Pay to Credit'
			    else ri.RedeemType END), t.itemid, r.description
		order by case when (case when ri.RedeemID in (7111, 7176) then 'Cash Back'
							when ri.RedeemID in (7178, 7179) then 'Pay to Credit'
							else ri.RedeemType END)  = 'Charity' then 1 
				      when (case when ri.RedeemID in (7111, 7176) then 'Cash Back'
						    when ri.RedeemID in (7178, 7179) then 'Pay to Credit'
							else ri.RedeemType END)  = 'Cash Back' or (case when ri.RedeemID in (7111, 7176) then 'Cash Back'
							when ri.RedeemID in (7178, 7179) then 'Pay to Credit'
							else ri.RedeemType END)  = 'Pay to Credit'  then 2 
				      else 3 end asc


END



