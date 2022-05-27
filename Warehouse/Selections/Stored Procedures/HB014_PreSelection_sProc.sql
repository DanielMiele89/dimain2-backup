-- =============================================
-- Author:  <Rory Francis>
-- Create date: <2020-03-20>
-- Description: < sProc to run preselection code per camapign >
-- =============================================
CREATE PROCEDURE Selections.HB014_PreSelection_sProc
AS
BEGIN

--Please take acquire customers only from the following table
 --caoe below for reference only

 /*********************************************************************/
 /****** I, Get Customers and attach common targetable qualities ******/
 /*********************************************************************/

 -- Get customers, add columns as needed
 If Object_ID('tempdb..#Base') Is Not Null Drop Table #Base
 Create Table #Base (FanID Int NOT NULL
 , Gender VarChar(1)
 , Age_Group VarChar(12)
 , CAMEO_CODE_GRP VarChar(50)
 , Target_DT Float
 , HeatmapScore Int)

 -- Fill table with chunk sizing
 Declare @MinID Int = 1
 , @MaxID Int
 , @Increment Int = 500000
 , @MaxIDValue Int = (Select Max(FanID) From Relational.Customer)

 Set @MaxID = @Increment

 While @MinID < @MaxIDValue
 Begin
 Insert Into #Base
 Select c.FanID
 , c.Gender
 , Case 
 When c.AgeCurrent < 18 Or c.AgeCurrent Is Null Then '99. Unknown'
 When c.AgeCurrent Between 18 And 24 Then '01. 18 to 24'
 When c.AgeCurrent Between 25 And 29 Then '02. 25 to 29'
 When c.AgeCurrent Between 30 And 39 Then '03. 30 to 39'
 When c.AgeCurrent Between 40 And 49 Then '04. 40 to 49'
 When c.AgeCurrent Between 50 And 59 Then '05. 50 to 59'
 When c.AgeCurrent Between 60 And 64 Then '06. 60 to 64'
 When c.AgeCurrent >= 65 Then '07. 65+' 
 End as Age_Group
 , IsNull((cam.[CAMEO_CODE_GROUP] + '-' + camg.CAMEO_CODE_GROUP_Category), '99. Unknown') 
 , Null as Target_DT
 , Null as HeatmapScore
 From Warehouse.Relational.Customer c With (NoLock)
 Left join Warehouse.Relational.CAMEO cam With (NoLock)
 on c.PostCode = cam.Postcode
 Left join Warehouse.Relational.CAMEO_CODE_GROUP camg With (NoLock)
 on cam.CAMEO_CODE_GROUP = camg.CAMEO_CODE_GROUP
 Inner join Warehouse.Relational.CINList cl 
 on c.SourceUID=cl.CIN
 Inner join Warehouse.MI.CustomerActivationPeriod cap
 on cap.FanID = c.FanID
 Where c.SourceUID Not In (Select Distinct SourceUID from Warehouse.Staging.Customer_DuplicateSourceUID)
 And c.FanID Between @MinID And @MaxID
 And c.CurrentlyActive = 1

 Set @MinID = @MinID + @Increment
 Set @MaxID = @MaxID + @Increment
 End

 -- This is heatmap
 If Object_ID('tempdb..#Activated_HM') Is Not Null Drop Table #Activated_HM
 Select a.FanID
 , a.Gender
 , a.Age_Group
 , a.CAMEO_CODE_GRP
 , a.Target_DT
 , a.HeatmapScore
 , lk2.ComboID as ComboID_2 -- Gender / Age group and Cameo grp
 Into #Activated_HM
 From #Base a -- full base
 Left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk2
 on a.Gender = lk2.Gender
 and a.CAMEO_CODE_GRP=lk2.CAMEO_grp
 and a.Age_Group=lk2.Age_Group


 If Object_ID('tempdb..#Activated_HM2') Is Not Null Drop Table #Activated_HM2
 Select b.FanID
 , b.Gender
 , b.Age_Group
 , b.CAMEO_CODE_GRP
 , b.Target_DT
 , b.HeatmapScore
 , b.ComboID_2
 , hm.Index_RR
 , lk.UnknownGroup
 , Case
 When lk.UnknownGroup = 1 Then 100
 Else Index_RR
 End as Response_Index
 Into #Activated_HM2
 From #Activated_HM b
 Left join Warehouse.InsightArchive.SalesSTO_HeatmapBrandCombo_Index hm
 on b.ComboID_2=hm.ComboID_2 
 and hm.brandid = 199
 Left join Warehouse.InsightArchive.HM_Combo_SalesSTO_Tool lk
 on lk.ComboID = hm.ComboID_2
 Where Case
 When lk.UnknownGroup = 1 Then 100
 Else Index_RR
 End >=100

If Object_ID('Warehouse.Selections.HB014_PreSelection') Is Not Null Drop Table Warehouse.Selections.HB014_PreSelection
Select FanID
Into Warehouse.Selections.HB014_PreSelection
FROM  #ACTIVATED_HM2


END
