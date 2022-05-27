create Procedure [Staging].[SSRS_R0151_CustomerTransactionsInMatch] (@PartnerID int, @FanID int)
As

Declare @PID int = @PartnerID, @FID int = @FanID

IF Object_id('tempdb..#Match') IS NOT NULL  DROP TABLE #Match 
SELECT		f.CompositeID,
			f.ID as FanID,
			ro.PartnerID,
			a.Name As PartnerName,
			m.TransactionDate,
			m.Amount,
			m.MerchantID,
			m.ID as MatchID
			Into #Match
			FROM		SLC_report.dbo.Fan f with (nolock)
			inner JOIN	SLC_Report.dbo.pan p with (nolock) ON p.CompositeID = f.CompositeID
			inner JOIN	SLC_Report.dbo.Match m with (nolock) on P.ID = m.PanID
			inner JOIN	SLC_Report.dbo.RetailOutlet ro with (nolock) on m.RetailOutletID = ro.ID
			inner join  SLC_Report.dbo.Partner as a with (nolock) on ro.PartnerID = a.id
			Where		@FanID = f.ID AND
						(@PartnerID is null or @PartnerID = ro.PartnerID)
--Order by a.Name,TransactionDate

Create Clustered Index cix_Match_MatchID on #Match (MatchID)

Select m.*, Case When t.matchID is not null then 'Yes' Else 'No' End as Incentivised 
From #Match as m
Left Outer join slc_report.dbo.Trans as t
	on m.MatchID = t.MatchID
Order by m.partnername, m.transactiondate desc