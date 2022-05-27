
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <13/01/2015>
-- Description:	<loads INSchemeSalesWorking with NLE and NLE monthly Payment totals >
-- =============================================
CREATE PROCEDURE [MI].[INSchemeSalesWorking_load_month_Payment_NLE] (@DateID int)
AS

-- no more needed, merged with INSchemeSalesWorking_load_month_Payment_Channel on 06/03/2015