-- =============================================
-- Author:		<Adam J Scott>
-- Create date: <20/06/2014>
-- Description:	<loads MI.VirtualPartnerList for monthly reporting>
-- =============================================
CREATE PROCEDURE [MI].[VirtualPartnerList_load]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--truncate table  MI.VirtualPartnerList
	insert into MI.VirtualPartnerList
  SELECT [PartnerID]
    --,[PartnerID] as DisplayPartnerid
	,0 as PartnerGroupID
	,[PartnerName] as VirtualPartnerName
	,1 as UseForReport
  FROM [Warehouse].[Relational].[Partner]
	Where [PartnerID] not in (SELECT [PartnerID] From MI.VirtualPartnerList)
Union All
  SELECT [PartnerID]
	--,[PartnerGroupID]  as DisplayPartnerid
	,[PartnerGroupID] as PartnerGroupID
	,[PartnerGroupName] as VirtualPartnerName
	,[UseForReport]
  FROM [Warehouse].[Relational].[PartnerGroups]
  Where [PartnerID] not in (SELECT [PartnerID]  From MI.VirtualPartnerList)
END