

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <12/02/2015>
-- Description:	<Populates MI.MemberssalesWorking with monthly data, online offline and payment totals>
-- =============================================
CREATE PROCEDURE [MI].[MemberssalesWorking_month_Payment_Channel_NonCore_load_NLE] (@DateID int)
	-- Add the parameters for the stored procedure here

AS

-- no more needed, merged with MemberssalesWorking_month_Payment_Channel_NonCore_load on 06/03/2015