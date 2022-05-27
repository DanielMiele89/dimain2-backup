


CREATE PROCEDURE [Report].[MIDS_Not_In_GAS]
AS
BEGIN
	
	SET NOCOUNT ON;


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
	FROM [Warehouse].[Staging].[R_0060_Outlet_NotinMIDS]
	left outer join [Warehouse].[Relational].[Partner] on
	[Warehouse].[Staging].[R_0060_Outlet_NotinMIDS].[PartnerID] = [Warehouse].[Relational].[Partner].[PartnerID]


END
