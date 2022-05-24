

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <22/10/2014>
-- Description:	<loads INSchemeSalesWorking with monthly totals, monthly Payment totals, monthly Channel totals>
-- =============================================
CREATE PROCEDURE [MI].[INSchemeSalesWorking_month_Payment_Channel_Cuml_loadBYPartner_nle] (@DateID int, @partnerid int)

AS
-- no more needed, merged with INSchemeSalesWorking_load_month_Payment_Channel on 06/03/2015