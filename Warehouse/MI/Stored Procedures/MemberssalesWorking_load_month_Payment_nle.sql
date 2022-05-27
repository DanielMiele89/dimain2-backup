

-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/10/2014>
-- Description:	<Populates MI.MemberssalesWorking with monthly NLE rolling data and NLE Rolling payment totals>
-- eddited on:  <28/01/2014>
-- =============================================
CREATE PROCEDURE [MI].[MemberssalesWorking_load_month_Payment_nle] (@DateID int)
	-- Add the parameters for the stored procedure here

AS

-- no more needed, merged with MemberssalesWorking_load_month_Payment on 06/03/2015