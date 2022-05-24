CREATE Procedure [Staging].[SSRS_R0131_MID_CreditCardTrans_Dates]
as
Select Convert(varchar,dateadd(m,-3,cast(getdate() as date)),110) as StartDate