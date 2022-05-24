-- =============================================
-- Author:		<Rory Frnacis>
-- Create date: <11/05/2018>
-- Description:	< sProc to run preselection code per camapign >
-- =============================================

Create Procedure Selections.WA149_PreSelection_sProc
AS
BEGIN
 SET ANSI_WARNINGS OFF;

--All customers are in #segmentAssignment
-- Select all acquire And lapsed From the above And put in the relevant offer
-- Select shoppers From Cell 03.0-10%
--      Cell 04.10-20%
--      Cell 05.20-30%
--       Cell 06.30-40%
--       Cell 07.40-50%
-- into the relevant offers, discard any remaining customers.  

	IF OBJECT_ID('tempdb..#CC') IS NOT NULL DROP TABLE #CC
	Select br.BrandID
		 , br.BrandName
		 , cc.ConsumerCombinationID
	Into #CC
	From Warehouse.Relational.Brand br
	Join Warehouse.Relational.ConsumerCombination cc
	 on br.BrandID = cc.BrandID
	Where br.BrandID in (425,379,21,292,5,92,485,254)
	Order By br.BrandName

	CREATE CLUSTERED INDEX ix_ComboID ON #cc(BrandID, ConsumerCombinationID)


	Declare @MainBrand SmallInt = 485  -- Main Brand 
		  , @TranDateLimit DateTime = DateAdd(Year,-1,GetDate())
		  , @MainBrand_spender_3m DateTime = DateAdd(Month, -3, GetDate())
		  , @MainBrand_spender_6m DateTime = DateAdd(Month, -6, GetDate())

	IF OBJECT_ID('tempdb..#FromSector') IS NOT NULL DROP TABLE #FromSector
	Select Distinct dtm.FromSector
	Into #FromSector
	From Warehouse.Relational.DriveTimeMatrix as dtm with (NOLOCK)
	Where dtm.DriveTimeMins <= 20
	And dtm.tosector in (Select Distinct Substring(PostCode, 1, CharIndex(' ', PostCode, 1) + 1) 
						 From Warehouse.Relational.Outlet
						 Where PartnerID = 4265)

	CREATE CLUSTERED INDEX CIX_FromSector_FromSector ON #FromSector(FromSector)


	IF OBJECT_ID('tempdb..#DuplicateSourceUID') IS NOT NULL DROP TABLE #DuplicateSourceUID
	Select Distinct SourceUID 
	Into #DuplicateSourceUID
	From Warehouse.Staging.Customer_DuplicateSourceUID

	CREATE CLUSTERED INDEX CIX_DuplicateSourceUID_SourceUID ON #DuplicateSourceUID (SourceUID)


	IF OBJECT_ID('tempdb..#CustomerList') IS NOT NULL DROP TABLE #CustomerList
	Select Distinct 
			cl.CINID
		  , cu.FanID
	Into #CustomerList
	From Warehouse.Relational.Customer cu
	Inner join Warehouse.Relational.CINList cl
		on cu.SourceUID = cl.CIN
	Where cu.CurrentlyActive = 1
	And not exists (Select 1
					From #DuplicateSourceUID dsuid
					Where cu.SourceUID = dsuid.SourceUID)
	And exists (Select 1
				From #FromSector fs
				Where cu.PostalSector = fs.FromSector)

	CREATE CLUSTERED INDEX CIX_CustomerList_CINID ON #CustomerList (CINID)


	IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions
	Select ct.CINID
		 , Sum(ct.Amount) as Sales
		 , Max(Case
	 			When cc.Brandid = @MainBrand And TranDate  > @MainBrand_spender_3m Then 1
	 			Else 0
	 		  End) as MainBrand_spender_3m
		 , Max(Case
	 			When cc.Brandid = @MainBrand And TranDate  > @MainBrand_spender_6m Then 1
	 			Else 0
	 		  End) as MainBrand_spender_6m
		 , Sum(case
	 			When cc.Brandid = @MainBrand Then ct.Amount
	 			Else 0
	 		  End) as MainBrand_sales
	Into #Transactions
	From Warehouse.Relational.ConsumerTransaction_MyRewards ct with (nolock)
	Join #cc cc on cc.ConsumerCombinationID = ct.ConsumerCombinationID
	Where 0 < ct.Amount
	And TranDate  > @TranDateLimit
	And Exists (Select 1
				From #CustomerList cl
				Where ct.CINID = cl.CINID)
	Group by ct.CINID

	CREATE CLUSTERED INDEX CIX_Transactions_CINID ON #Transactions (CINID)

	--  Assign Shopper segments
	If Object_ID('Warehouse.Selections.WA_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA_PreSelection
	Select x.FanID
	--	 , x.CINID
	--	 , x.MainBrand_spender_3m
	--	 , x.MainBrand_spender_6m
	--	 , x.SOW
	--	 , x.SOW_rnd
		 , Case
				When SOW_rnd = 0 Then 'Cell 03.0-10%'
				When SOW_rnd = 10 Then 'Cell 03.0-10%'
				When SOW_rnd = 20 Then 'Cell 04.10-20%'
				When SOW_rnd = 30 Then 'Cell 05.20-30%'
				When SOW_rnd = 40 Then 'Cell 06.30-40%'
				When SOW_rnd = 50 Then 'Cell 07.40-50%'
				When SOW_rnd = 60 Then 'Cell 08.50-60%'
				When SOW_rnd = 70 Then 'Cell 09.60-70%'
				When SOW_rnd = 80 Then 'Cell 10.70-80%'
				When SOW_rnd = 90 Then 'Cell 11.80-90%'
				When SOW_rnd = 100 Then 'Cell 12.90-100%'
				Else 'Cell 00.Error'
		   End as Flag
	Into Warehouse.Selections.WA_PreSelection
	From (
		Select cl.CINID
			 , cl.fanid
			 , MainBrand_spender_3m
			 , MainBrand_spender_6m
			 , Cast(MainBrand_sales as Float) / Cast(sales as Float) as SOW
			 , Round(Ceiling(Cast(MainBrand_sales as Float) / cast(sales as Float)*100),-1) as SOW_rnd
		From #CustomerList cl
		Left Join #Transactions t
			on cl.CINID = t.CINID) x

	CREATE CLUSTERED INDEX CIX_WAPreSelection_FlagFanID ON Warehouse.Selections.WA_PreSelection (Flag, FanID)

	If Object_ID('Warehouse.Selections.WA149_PreSelection') Is Not Null Drop Table Warehouse.Selections.WA149_PreSelection
	Select FanID
	Into Warehouse.Selections.WA149_PreSelection
	From Warehouse.Selections.WA_PreSelection
	Where Flag = 'Cell 03.0-10%'

End