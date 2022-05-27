-- =============================================
-- Author:  <Rory Frnacis>
-- Create date: <11/05/2018>
-- Description: < sProc to run preselection code per camapign >
-- =============================================

CREATE Procedure [Selections].[MOR017_PreSelection_sProc]
AS
BEGIN

	Declare @BrandID Int = (Select BrandID
							From Warehouse.Relational.Brand
							Where BrandName = 'Morrisons')		--		BrandId = 292
		  , @CampaignStartDate Date = '2018-10-11'
 
	If Object_ID('tempdb..#IronOfferMember') Is Not Null Drop Table #IronOfferMember
	Select Distinct CompositeID
	Into #IronOfferMember
	From Warehouse.Relational.IronOfferMember
	Where IronOfferID = 15922

	If Object_ID('tempdb..#Customer') Is Not Null Drop Table #Customer
	Select cu.FanID
		 , cu.SourceUID
		 , cu.CompositeID
		 , cl.CINID
	Into #Customer
	From #IronOfferMember iom
	Inner join Warehouse.Relational.Customer cu
		on iom.CompositeID = cu.CompositeID
	Inner join Warehouse.Relational.CINList cl
		on cu.SourceUID = cl.CIN
	Where Not Exists (Select 1
					  From Warehouse.Staging.Customer_DuplicateSourceUID dsu
					  Where cu.SourceUID = dsu.SourceUID
					  and dsu.EndDate Is Null)

	If Object_ID('tempdb..#Over50Spend') Is Not Null Drop Table #Over50Spend
	Select cu.FanID
	Into #Over50Spend
	From Warehouse.Relational.PartnerTrans ct
	Inner join #Customer cu
		on ct.FanID = cu.FanID
	Where ct.TransactionDate >= @CampaignStartDate
	And ct.PartnerID = 4263
	Group by cu.FanID
	Having Max(ct.TransactionAmount) >= 50

	If Object_ID('Warehouse.Selections.MOR017_PreSelection') Is Not Null Drop Table Warehouse.Selections.MOR017_PreSelection
	Select FanID
	Into Warehouse.Selections.MOR017_PreSelection
	From #Over50Spend

END