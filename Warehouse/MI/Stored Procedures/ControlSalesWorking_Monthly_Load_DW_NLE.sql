
--USE Warehouse_Dev
--GO
--/****** Object:  StoredProcedure MI.ControlSalesWorking_load_month_Payment_Channel    Script Date: 03/11/2014 16:57:57 ******/
--SET ANSI_NULLS ON
--GO
--SET QUOTED_IDENTIFIER ON
--GO truncate table MI.ControlSalesWorking
-- =============================================
-- Author:		Adam
-- Create date:  13/1/2015
-- Description:	Control Sales Monthly
-- =============================================
CREATE PROCEDURE [MI].[ControlSalesWorking_Monthly_Load_DW_NLE] (@DateID int, @Partnerid int, @ControlPartnerid int)

AS
-- no more needed, merged with ControlSalesWorking_Monthly_Load_DW on 06/03/2015