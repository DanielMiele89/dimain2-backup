

Create view [SmartEmail].[vw_SmartEmailDailyData_v2] 
As
SELECT [Email]
      ,a.[FanID]
      ,[ClubID]
      ,[ClubName]
      ,[FirstName]
      ,[LastName]
      ,Convert(varchar,[DOB],103) as DOB
      ,Cast([Sex] as tinyint) Sex
      ,[FromAddress]
      ,[FromName]
      ,[ClubCashAvailable]
      ,[ClubCashPending]
      ,[PartialPostCode]
      ,[Title]
      ,Convert(varchar,[AgreedTcsDate],103)+ ' ' +Convert(varchar,[AgreedTcsDate],108) as [AgreedTcsDate]
      ,Coalesce(lsco.LionSendID, o.[LionSendID],0) as SmartEmailSendID
      ,[Offer1]
      ,[Offer2]
      ,[Offer3]
      ,[Offer4]
      ,[Offer5]
      ,[Offer6]
      ,[Offer7]
      ,Convert(varchar,[Offer1StartDate],103)[Offer1StartDate]
      ,Convert(varchar,[Offer2StartDate],103)[Offer2StartDate]
      ,Convert(varchar,[Offer3StartDate],103)[Offer3StartDate]
      ,Convert(varchar,[Offer4StartDate],103)[Offer4StartDate]
      ,Convert(varchar,[Offer5StartDate],103)[Offer5StartDate]
      ,Convert(varchar,[Offer6StartDate],103)[Offer6StartDate]
      ,Convert(varchar,[Offer7StartDate],103)[Offer7StartDate]
      ,Convert(varchar,[Offer1EndDate],103)[Offer1EndDate]
      ,Convert(varchar,[Offer2EndDate],103)[Offer2EndDate]
      ,Convert(varchar,[Offer3EndDate],103)[Offer3EndDate]
      ,Convert(varchar,[Offer4EndDate],103)[Offer4EndDate]
      ,Convert(varchar,[Offer5EndDate],103)[Offer5EndDate]
      ,Convert(varchar,[Offer6EndDate],103)[Offer6EndDate]
      ,Convert(varchar,[Offer7EndDate],103)[Offer7EndDate]
      ,[RedeemOffer1]
      ,[RedeemOffer2]
      ,[RedeemOffer3]
      ,[RedeemOffer4]
      ,[RedeemOffer5]
      ,Convert(varchar,[RedeemOffer1EndDate],103)[RedeemOffer1EndDate]
      ,Convert(varchar,[RedeemOffer2EndDate],103)[RedeemOffer2EndDate]
      ,Convert(varchar,[RedeemOffer3EndDate],103)[RedeemOffer3EndDate]
      ,Convert(varchar,[RedeemOffer4EndDate],103)[RedeemOffer4EndDate]
      ,Convert(varchar,[RedeemOffer5EndDate],103)[RedeemOffer5EndDate]
      ,[WelcomeEmailCode]
      ,Cast([IsDebit] as Tinyint) as IsDebit
      ,Cast([IsCredit] as TinyInt) as IsCredit
      ,Cast([Nominee] as TinyInt) as Nominee
      ,Cast([RBSNomineeChange] as Tinyint) as [RBSNomineeChange]
      ,Cast([LoyaltyAccount] as Tinyint) as LoyaltyAccount
      ,Cast([IsLoyalty] as Tinyint) as IsLoyalty
      ,Convert(varchar,[FirstEarnDate],103)[FirstEarnDate]
      ,[FirstEarnType]
      ,Convert(varchar,[Reached5GBP],103)[Reached5GBP]
      ,Cast([Homemover] as Tinyint) as Homemover
      ,[Day60AccountName]
      ,[Day120AccountName]
      ,Cast([JointAccount]  as Tinyint) as JointAccount
      ,[FulfillmentTypeID]
      ,[CaffeNeroBirthdayCode]
      ,Convert(varchar,[ExpiryDate],103)[ExpiryDate]
      ,[LvTotalEarning]
      ,[LvCurrentMonthEarning]
      ,[LvMonth1Earning]
      ,[LvMonth2Earning]
      ,[LvMonth3Earning]
      ,[LvMonth4Earning]
      ,[LvMonth5Earning]
      ,[LvMonth6Earning]
      ,[LvMonth7Earning]
      ,[LvMonth8Earning]
      ,[LvMonth9Earning]
      ,[LvMonth10Earning]
      ,[LvMonth11Earning]
      ,[LvCPOSEarning]
      ,[LvDPOSEarning]
      ,[LvDDEarning]
      ,[LvOtherEarning]
      ,[LvCurrentAnniversaryEarning]
      ,[LvPreviousAnniversaryEarning]
      ,[LvEAYBEarning]
      ,Cast([Marketable] as tinyint) as Marketable
      ,[CustomField1]
      ,[CustomField2]
      ,[CustomField3]
      ,[CustomField4]
      ,[CustomField5]
      ,[CustomField6]
      ,[CustomField7]
      ,[CustomField8]
      ,[CustomField9]
      ,[CustomField10]
      ,[CustomField11]
      ,Convert(Varchar,[CustomField12],103)[CustomField12]
  FROM [SmartEmail].[DailyData] as a
  LEFT JOIN [SmartEmail].[LionSend_CustomerOverride] lsco
	ON a.FanID = lsco.FanID
  Left Outer join [SmartEmail].[OfferSlotData] as o
        on a.FanID = o.FanID
  Left Outer join [SmartEmail].[RedeemOfferSlotData] as ro
        on a.FanID = ro.FanID
		and o.LionSendID = ro.LionSendID
