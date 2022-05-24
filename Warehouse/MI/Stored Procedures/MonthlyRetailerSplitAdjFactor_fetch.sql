-- =============================================
-- Author:		<Adam Scott>
-- Create date: <18/06/2014>
-- Description:	<Fetches AdjFactor for mid split reports>
-- =============================================
CREATE PROCEDURE MI.MonthlyRetailerSplitAdjFactor_fetch
	-- Add the parameters for the stored procedure here
	(@MonthID int)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	 Select MonthID
		,Partnerid
		,1 as Splitid
		,1 as StatusID
		,[AdjFactor_Split1_Status1_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status1_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,1 as Splitid
		,2 as StatusID
		,[AdjFactor_Split1_Status2_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status2_SPC] is not null
 union all
 Select MonthID
		,Partnerid
 		,1 as Splitid
		,3 as StatusID
		,[AdjFactor_Split1_Status3_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status3_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,1 as Splitid
		,4 as StatusID
		,[AdjFactor_Split1_Status4_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status4_SPC] is not null
union all 
 Select MonthID
		,Partnerid
 		,1 as Splitid
		,5 as StatusID
		,[AdjFactor_Split1_Status5_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status5_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,1 as Splitid
		,6 as StatusID
		,[AdjFactor_Split1_Status6_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split1_Status6_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,1 as StatusID
		,[AdjFactor_Split2_Status1_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status1_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,2 as StatusID
		,[AdjFactor_Split2_Status2_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status2_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,3 as StatusID
		,[AdjFactor_Split2_Status3_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status3_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,4 as StatusID
		,[AdjFactor_Split2_Status4_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status4_SPC] is not null
union all
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,5 as StatusID
		,[AdjFactor_Split2_Status5_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status5_SPC] is not null
union all	
 Select MonthID
		,Partnerid
 		,2 as Splitid
		,6 as StatusID
		,[AdjFactor_Split2_Status6_SPC] as AdjFactor_SPC
	FROM [Warehouse].[Relational].[RetailAdjustmentFactor]
	where monthid = @MonthID and [AdjFactor_Split2_Status6_SPC] is not null
	

END