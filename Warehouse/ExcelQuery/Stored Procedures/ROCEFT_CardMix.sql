-- =============================================
-- Author:		<Shaun H>
-- Create date: <21/06/2017>
-- Description:	<Create the Card mix statistics>
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_CardMix]
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;


	-- Retrieve a PublisherList
	IF OBJECT_ID('tempdb..#Publisher') IS NOT NULL DROP TABLE #Publisher
	Select	PublisherID
			,PublisherName
	Into	#Publisher
	From	Warehouse.ExcelQuery.ROCEFT_Publishers
	Where	PublisherName <> 'R4G'

	CREATE CLUSTERED INDEX ix_PublisherID ON #Publisher(PublisherID)


	DECLARE @StartDate DATE = GETDATE()

	-- Retrieve all cards registered on any of the NFI schemes
	IF OBJECT_ID('tempdb..#CardList') IS NOT NULL DROP TABLE #CardList
	Select	distinct f.ID
			,f.CompositeID
			,f.ClubID as PublisherID
			,pub.PublisherName
			,p.PaymentCardID
			,pc.CardTypeID
			,pc.MaskedCardNumber
	Into	#CardList
	From #Publisher pub 
	INNER loop JOIN SLC_Report.dbo.Fan as f 		
		ON	pub.PublisherID = f.ClubID	
	INNER JOIN SLC_Report.dbo.Pan as P 
		ON	f.CompositeID = p.CompositeID
	INNER JOIN	SLC_Report.dbo.PaymentCard pc 
		ON	p.PaymentCardID = pc.ID
	Where   p.AdditionDate < DATEADD(dd, 1, @startdate) 
		and	(p.RemovalDate IS NULL OR p.RemovalDate > @StartDate)
		and (
				(      
					p.DuplicationDate IS NULL OR p.DuplicationDate > @StartDate
				)
			OR 
				(
					p.DuplicationDate <= @StartDate 
				AND EXISTS (	Select	1
								From	SLC_Report.dbo.Pan ps 
								Join	SLC_Report.dbo.Fan fs ON ps.CompositeID = fs.CompositeID
								Where	ps.PaymentCardID = p.PaymentCardID
									and fs.ClubID = 141 -- P4L
							) 
				)
			)

	-- Perform a 'dumb' assignment of the AMEX/VISA/MasterCard Labelling
	IF OBJECT_ID('tempdb..#LabelledCards') IS NOT NULL DROP TABLE #LabelledCards
	Select	*
			,case
				when CardTypeID = 1 Then 'Credit'
				when CardTypeID = 2 Then 'Debit'
				else NULL
			 end as CreditOrDebit
			,case
				when MaskedCardNumber like '3%' then 'AMEX'
				when MaskedCardNumber like '4%' then 'VISA'
				when MaskedCardNumber like '5%' then 'Mastercard'
				else 'Other'
			 end as CardName
	Into	#LabelledCards
	From	#CardList

	CREATE CLUSTERED INDEX ix_CompositeID ON #LabelledCards(CompositeID)

	-- Find Topline Metrics (which will be needed in the join)
	IF OBJECT_ID('tempdb..#ToplineMetrics') IS NOT NULL DROP TABLE #ToplineMetrics
	Select	PublisherID
			,PublisherName
			,count(distinct CompositeID) as Cardholders
			,count(distinct PaymentCardID) as Cards
	Into	#ToplineMetrics
	From	#CardList
	Group By PublisherID
			,PublisherName


	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_CardsMix

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_CardsMix
		Select	a.PublisherID
				,a.PublisherName
				,a.CardName
				,coalesce(1.0*a.Cardholders/nullif(1.0*b.Cardholders,0),0) as Proportion_Cardholders
				,coalesce(1.0*a.Cards/nullif(1.0*b.Cards,0),0) as Proportion_Cardholders
		From	(
						Select	PublisherID
								,PublisherName
								,CardName
								,count(distinct CompositeID) as Cardholders
								,count(distinct PaymentCardID) as Cards
						From	#LabelledCards
						Group By PublisherID
								,PublisherName
								,CardName
					UNION
						Select	PublisherID
								,PublisherName
								,'MasterCard & AMEX' as CardName
								,count(distinct CompositeID) as Cardholders
								,count(distinct PaymentCardID) as Cards
						From	#LabelledCards
						Where	CardName in ('AMEX','Mastercard')
						Group By PublisherID
								,PublisherName
				) a
		Join	#ToplineMetrics b on a.PublisherID = b.PublisherID
		UNION
		Select	999 as PublisherID
				,'Other' as PublisherName
				,a.CardName
				,coalesce(1.0*sum(a.Cardholders)/nullif(1.0*sum(b.Cardholders),0),0) as Proportion_Cardholders
				,coalesce(1.0*sum(a.Cards)/nullif(1.0*sum(b.Cards),0),0) as Proportion_Cardholders
		From	(
						Select	PublisherID
								,PublisherName
								,CardName
								,count(distinct CompositeID) as Cardholders
								,count(distinct PaymentCardID) as Cards
						From	#LabelledCards
						Group By PublisherID
								,PublisherName
								,CardName
					UNION
						Select	PublisherID
								,PublisherName
								,'MasterCard & AMEX' as CardName
								,count(distinct CompositeID) as Cardholders
								,count(distinct PaymentCardID) as Cards
						From	#LabelledCards
						Where	CardName in ('AMEX','Mastercard')
						Group By PublisherID
								,PublisherName
				) a
		Join	#ToplineMetrics b on a.PublisherID = b.PublisherID
		Group By a.CardName

	--IF OBJECT_ID('Warehouse.ExcelQuery.ROCEFT_CardsMix') IS NOT NULL DROP TABLE Warehouse.ExcelQuery.ROCEFT_CardsMix
	--CREATE TABLE Warehouse.ExcelQuery.ROCEFT_CardsMix
	--	(	
	--		PublisherID int NOT NULL
	--		,PublisherName varchar(50) NOT NULL
	--		,CardName varchar(50) NOT NULL
	--		,Proportion_Cardholders decimal(12,11) NOT NULL
	--		,Proportion_Cards decimal(12,11) NOT NULL
	--	)
END
