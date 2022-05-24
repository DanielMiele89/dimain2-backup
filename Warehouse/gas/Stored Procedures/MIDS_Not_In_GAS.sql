


CREATE PROCEDURE [gas].[MIDS_Not_In_GAS]
AS
BEGIN
	
	SET NOCOUNT ON;

	select * from [Warehouse].[Staging].[R_0060_Outlet_NotinMIDS_Report]

END
