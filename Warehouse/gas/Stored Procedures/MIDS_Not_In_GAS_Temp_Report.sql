


CREATE PROCEDURE [gas].[MIDS_Not_In_GAS_Temp_Report]
AS
BEGIN
	
	SET NOCOUNT ON;
 IF OBJECT_ID(N'tempdb..#MIDSNotInGAStemp') IS NOT NULL
BEGIN
	DROP TABLE #MIDSNotInGAStemp
END

IF OBJECT_ID(N'Staging.R_0060_Outlet_NotinMIDS_Report', N'U') IS NOT NULL  
    DROP TABLE [Staging].[R_0060_Outlet_NotinMIDS_Report]; 

	SELECT  
	[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[ConsumerCombinationID]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[MerchantID]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Narrative]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[LocationCountry]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[MCC]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[MCCDesc]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[FirstTran]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[LastTran]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Trans]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Offline Tranx]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Offline Cashback]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Online Tranx]
      ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[Online Cashback]
	  ,[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[PartnerID]
	  ,[Warehouse].[Relational].[Partner].[PartnerName]
	  INTO #MIDSNotInGAStemp
	FROM [Warehouse].[Staging].[R_0060_Outlet_NotinMIDS]
	left outer join [Warehouse].[Relational].[Partner] on
	[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[PartnerID] = [Warehouse].[Relational].[Partner].[PartnerID]

	select * 
	into [Warehouse].[Staging].[R_0060_Outlet_NotinMIDS_Report]
	from #MIDSNotInGAStemp

END