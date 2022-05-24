

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <12/02/2015>
-- Description:	<Populates MI.MemberssalesWorking with monthly data, online offline and payment totals>
CREATE PROCEDURE [MI].[MemberssalesWorking_month_Payment_Channel_Cuml_ByPartner_NLE] (@DateID int, @partnerid int )
	-- Add the parameters for the stored procedure here

	as
-- no more needed, merged with [MI].[MemberssalesWorking_month_Payment_Channel_Cuml_ByPartner] on 06/03/2015