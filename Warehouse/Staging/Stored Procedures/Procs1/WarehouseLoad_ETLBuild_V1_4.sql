/*
Author:		Suraj Chahal	
Date:		23nd March 2013
Purpose:	This Procedure calls a number of other procedures which each contribute to the building of the 
		warehouse. Once a table has been reloaded or updated, the procedure adds an entry to a table called
		Warehouse.Staging.Joblog which stores all the information on how long a specific table takes to build,
		the tables updated and a count of how many rows were affected by the proceedure.
		
Update:		21-05-2013 SC - Added exec Staging.WarehouseLoad_WebLogins and 
				Staging.WarehouseLoad_TidyUp_NominatedLionSendComponent Procedure to the end.
		23-05-2013 SC - Added update to WarehouseLoad_SmartFocusEmailData_V1_3 which includes EmailEvent as an 
				incremental load
		23-05-2013 SC - Added update to WarehouseLoad_OfferData_V1_3 which includes LionSendComponent as an 
				incremental load
		27-06-2013 SC - Added updated Staging.WarehouseLoad_MatchCardHolderPresent_V1_3 to the build and added updated
						Staging.WarehouseLoad_Customer_V1_4 procedure. 
		17-07-2013 SC - Added Exec Staging.CustomerJourney_and_Lapsing to the load.
		27-07-2013 SC - added Staging.WarehouseLoad_PartnerTransAndOutlet_V1_5 to load
		02-08-2013 SC - Added WarehouseLoad_NominatedMember_UpdateCustomerJourney to load
		12-08-2013 SC - Added Start and End date to ETL Build and Updated Customer_V1_6 to load
		13-08-2013 SC - Added WarehouseLoad_DailyAboveBaseOffersV1 to load
		26-09-2013 SC - Added Staging.WarehouseLoad_UpdateCustomerJourney to load and took out NominatedMember and CustomerJourneyAndLapsing
		21-11-2013 SC - Added Staging.WarehouseLoad_Database_TableRowCounts to load to get counts of tables
		22-11-2013 SB - Added Staging.WarehouseLoad_Cashback_Balances_V1_0 to get balances (availavle and pending
		26/11/2013 SB - Added Staging.WarehouseLoad_CBP_DailyReportData to produce data for daily report for basic validation
		27/12/2013 SB - Amended [Staging].[WarehouseLoad_SmartFocusEmailData_V1_N] to V1_5 to fix infinite loop caused by last row not 
						belonging to CBP customer.
		30/12/2013 SB - Created Staging.WarehouseLoad_Customer_V1_10 to make sure Marketablebyemail takes note of Postcode.
		06/01/2014 SB - Created Staging.WarehouseLoad_Customer_V1_11 to make sure Activated are not not deemed deactivated.
		22/01/2014 SB - Created Staging.WarehouseLoad_Customer_V1_12 to speed up process.
		06/02/2014 SB - Amended to use new redemtpions sp
		07/02/2014 SB - Split out IO, IOM & LSC Builds so as easier to work on
		11/02/2014 SB - Changed to use new version of PartnerTrans and Outlet Builder (v13)
		14/02/2014 SB - Amended to use updated Headroom and new version of corrections
		15/02/2014 SB - Amends made to try to speed up Customer and PartnerTrans
		11/03/2014 SC - Made HTMRemovePartnerDataTables and NLSCTidyUp run on a saturday rather than everyday.
		13/03/2014 SC - Removed EXEC Staging.WarehouseLoad_TidyUp_NominatedLionSendComponentV1_1 as no longer required
		28/03/2014 SB - Amended to exec Cineworld fix.
		31/03/2014 SB - Amended to populate Project Sandy Data
		01/04/2014 SB - Amended to Populate Registered field in Customer Table
		09/04/2014 SB - Add in new Eligigble for HTM and SoW
						Add entry to CJ Report SP
		15/04/2014 SC - Added EXEC [Staging].[Partner_GenerateTriggerMember]
		28-04-2014 SB - Updated so Non-Cinlist members are added to SoW
		29-04-2014 SB - Updated so that old SoW tables are removed
		30-04-2014 SB - IronOfferMember Missing base offers query added and customer 15 added
		12-05-2014 SB - Updated to deal with hardbounces that amend email address after bounce
		16-05-2014 SB - Updated to include adjusted Customer Journey Stored Procedure
		20-06-2014 SB - Removing need for CardHolderPresentData Build
		07-07-2014 SB - Add Additional Cashback Calculation
		11-07-2014 SB - Added SoW Fix and Amended Additional Cashback Calculation
		14-07-2014 SB - Amended to make sure both sides of the SoW run on the same day
		15-07-2014 SC - Added [Staging].[WarehouseLoad_IronOffer_PartnerCommissionRule] to Build
		18-07-2014 SB - Add CJ DailyLoad stored procedure to log CJs day by day until WR given time
		23-07-2014 SC - added EXEC Staging.Partner_GenerateTriggerMember 12
		01-08-2014 SB - Amended which SoW was run
		08-08-2014 SB - Add Monthly report for MIDs not in GAS
		12-08-2014 SB - Run LSC at weekends
		14-08-2014 SB - Exec Staging.WarehouseLoad_CustomerPaymentMethodsAvailable, 
						and Exec [Staging].[WarehouseLoad_AdditionalCashbackAwardsV1_2]
						and Exec [Staging].[WarehouseLoad_PartnerTransAndOutlet_V1_19]
		20-08-2014 SC - added WarehouseLoad_Customer_V1_16 - which has no account Key
		21-08-2014 SC - commented out Exec Staging.WarehouseLoad_SandyAccounts AND Exec [Staging].[SSRS_CustomerJourneyAssessmentV1_3_DataSetPop]
						Removed [Staging].[WarehouseLoad_PartnerTransAndOutlet_V1_19] and added
						EXEC Staging.WarehouseLoad_Outlet_V1  &  EXEC Staging.WarehouseLoad_PartnerTrans_V1
		09-09-2014 SC - Changed Indexing on Customer build, Outlet, PartnerTrans, Redemptions and changed Procedure, CJS
		16-09-2014 SB - Removal of Exec Staging.CJ_DailyList
		19-09-2014 SB - Remove Daily 'Exec [Staging].[WarehouseLoad_CBP_DailyReportDataV1_1] @Date'
		23-09-2014 SB - IronOfferMember code commented out so we can run manually and
						swapped in new SP [Staging].[WarehouseLoad_CustomerPaymentMethodsAvailableV1_1]
		23-09-2014 SC - Added Staging.WarehouseLoad_CustomerMarketableByEmailStatus to load
		25-09-2014 SB - Changed to point to new SoW weekly SP
		26-09-2014 SB - Changed to deal with CC changes
		30-09-2014 SB - Calls EXEC Staging.WarehouseLoad_Customer_V1_18 so that test records are excluded
						calls Exec Staging.WarehouseLoad_AdditionalCashbackAwardsV1_6
		30-09-2014 SC - calls EXEC Staging.Partner_GenerateTriggerMember_WeeklyRun added
		18-10-2014 SB - Edited to caal new versions of SPs: 'WarehouseLoad_Customer_V1_19','WarehouseLoad_Customer_HardBounceEmailChangeV1_1' & 
						'CustomerUnsubscribesV1_2'
		29-10-2014 SB - Changed to run [Staging].[WarehouseLoad_RedemptionItem_V1_6]
		03-11-2014 SB - Changed to run Staging.WarehouseLoad_PartnerTrans_V1_6
		04-11-2014 SB - Changed to run [Staging].[WarehouseLoad_Corrections_V1_7] & Staging.WarehouseLoad_IronOffer_V1_1
		12-11-2014 SB - Changed to run Staging.WarehouseLoad_RedemptionItem_V1_7 - to deal with new redemptions being added
		12-11-2014 SC - Added EXEC Staging.Populate_SFDPostUploadAssessmentData_Member to build
		19-11-2014 SB - Changed to run [Staging].[WarehouseLoad_RedemptionItem_V1_8]
		25-11-2014 SB - changed to run Staging.WarehouseLoad_PartnerTrans_V1_7
		25-11-2014 SC - Added Staging.SSRS_R0055_ReportingOPEPerformance_LoadDataTablesV2
		02-12-2014 SC - Added [Staging].[SSRS_R0057_WeeklyEmailPerformanceReport_Load]
		03-12-2014 SB - Amended to Exec [Staging].[WarehouseLoad_AdditionalCashbackAwards_ItemAlterationsV1_0] and
									    [Staging].[ShareofWallet_EligibleCustomersV1_3]
		04-12-2014 SB - Amended to add the Exec 
		17/12/2014 SC - Add GeoDemographic HeatMap SPs BUILD to run every Sunday after the SoW
		06-01-2014 SC - Added EXEC Warehouse.Staging.Partner_GenerateTriggerMember_UC_WeeklyRun
		10-02-2015 SB - Added Exec [Staging].[WarehouseLoad_AdditionalCashbackAdjustmentsV1_0]
		04-03-2015 SB - Amended SP to run new version of SP - exec Staging.WarehouseLoad_Customer_HardBounceEmailChangeV1_2
		08-04-2015 SB - Amended to remove old reduced frequency code
		05-05-2015 SC - Added [Staging].[Update_BaseAndNonCore_StartEndDates]
		14-05-2015 SC - Added Staging.WarehouseLoad_Partner_CurrentlyActive
		27-05-2015 SB - Add Exec [Staging].[CustomerUpdate_MOT3] and remove reference to Exec [Staging].[RBSG_MonthlyRepV1_3]
		15-06-2015 SC - Added EXEC Staging.WarehouseLoad_MOT3Week1_Load to run every monday
		17-06-2015 SB - Add Exec [Staging].[WarehouseLoad_Customer_HardbounceEmailChangePart2] and
						EXEC Staging.WarehouseLoad_IronOffer_V1_2
		18-06-2015 SB - exec Staging.WarehouseLoad_Customer_EmailChange1
		24-06-2015 SB - EXEC Staging.WarehouseLoad_RedemptionItem_V1_10
		25-06-2015 SB - EXEC Staging.SSRS_R0077_Gogarburn_Trans_tobeIncentivised - this is scheduled for Tuesdays
		02-07-2015 SC - commented out reduced frequency and partner trigger SPs and moved them to ETL_SOW stored procedure
		08-07-2015 SB - Exec Staging.WarehouseLoad_Customer_M2Wk1_FirstSpend
		14-07-2015 SB - Loyalty Additions (Part 1)
		15-07-2015 SB - Loyalty Additions (Part 2)
		16-07-2015 SB - Exec Staging.WarehouseLoad_AdditionalCashbackAdjustmentsV1_1 &
						exec Staging.WarehouseLoad_AdditionalCashbackAwardsV1_8
		19-08-2015 SB - Exec Staging.WarehouseLoad_DailyLoadChecks_Table
		16-09-2015 SC - Added DD Report Data Calculation
		09-10-2015 SB - Changes for Start of Phase 2
		16-10-2015 SB - New Additions for Phase 2 of Loyalty - Exec Staging.WarehouseLoad_WGUpdate_V1_0
		16-12-2015 SB - Amended to include New Redemption Code
		28-01-2016 SB - Make deceased NON Marketable By Email
		09-02-2016 SB - Change ACA SP call
		25-02-2016 SB - New version of MarketableByEmail Stored Procedure - Exec [Staging].[WarehouseLoad_CustomerMarketableByEmailStatusV1_1]
		09-06-2016 SB - Call to new SP - Exec Staging.Warehouseload_LogSFDDailyLoad
		27-06-2016 SB - Changed to do append to PartnerTrans during the week
		30-06-2016 SB - Amendment to run Append version of ACA table.
		05-08-2016 SB - add code to update WelcomeOffer Table
		09-11-2016 SB - change to new Cashback Balances stored Procedure
		21/11/2016 SB - Add SP call Staging.Warehouseload_SFD_MasterlistExclusions,
						Commented out link to EXEC Staging.WarehouseLoad_Database_TableRowCountsV1_1
		02/02/2017 SB - changes made to accommodate IOM as LSC changes
		17-02-2017 SB - Added Exec Staging.Warehouseload_PartnerVsBrandsLookup
		18-05-2017 SB - Code Introduced to load ERA leaded Redemptions
		22-06-2017 SB - Changes to improve processing speed
		09-08-2017 SB - Change Exec WarehouseLoad_IronOfferMember_MissingBaseOffersCheck_V1 to run on Saturdays as
						it has only added records on this day since 2015. Also 
						Exec Staging.WarehouseLoad_Redemptions_V1_11 updated to be more efficient
		29-09-2017 SB - Append versions of PT and ACA run on Saturday due to congestion on Server, processes have been running into Sunday.
						Removal of R_0097 as no longer needed, report superceded.
		23-11-2017 SB - Deployment of code [Staging].[WarehouseLoad_Cashback_Balances_V1_2], this is to co-ordinate with new table indexes structure.
		13-12-2017 SB - Changed to remove full load version of ApplePay trans
		27-12-2017 SB - Adjustment made to call SP Staging.WarehouseLoad_AdditionalCashbackAwards_CC_MonthlyAwards as replacement for
						Staging.WarehouseLoad_AdditionalCashbackAwards_CC_Amazon as this rebuilds everytime it runs
		28-12-2017 SB - Call made to SP Exec Staging.WarehouseLoad_IronOfferMembers_DailySmallLoad this loads yesterdays memberships however 
						emails if level of memberships is to high.
		22/02/2018 ZT - Added temporary fix to set customer back to unsubscribed = 0 and marketablebyemail = 1 to alow for redemption code resends
		01/03/2018 JEA - Modified to use WarehouseLoad_Redemptions_V1_12 to maintain the GiftAid column 
		09/07/2018 RF - Added SP call WarehouseLoad_MIDTrackingGAS
		21/09/2018 RF - WarehouseLoad_IronOfferMembers_DailySmallLoad updated to WarehouseLoad_IronOfferMembers_DailySmallLoad_V2
		04/12/2018 RF - WarehouseLoad_IronOfferMembers_DailySmallLoad updated to WarehouseLoad_IronOfferMembers_DailySmallLoad_V2


*/

CREATE PROCEDURE [Staging].[WarehouseLoad_ETLBuild_V1_4]
AS
BEGIN

/*--------------------------------------------------------------------------------------------------
-----------------------------Write Start DateTime entry to JobLog Table-----------------------------
----------------------------------------------------------------------------------------------------*/


Insert into staging.JobLog
Select	StoredProcedureName = 'ETL_Build_Start',
		TableSchemaName = '',
		TableName = '',
		StartDate = GETDATE(),
		EndDate = null,
		TableRowCount  = null,
		AppendReload = NULL

Exec Staging.Warehouseload_SFD_MasterlistExclusions
Exec Staging.WarehouseLoad_LogSizeof_InsightArchiveData
Exec Staging.WarehouseLoad_DailyLoadChecks_Table

-- commented out chrism 20180523
-- Exec Staging.Warehouseload_LogSFDDailyLoad -- Invalid object name 'slc_report.dbo.SFDDailyDataLog'.
-- commented out chrism 20180523

EXEC staging.WarehouseLoad_HomeMover_Details_V1_3
exec Staging.WarehouseLoad_Customer_EmailChange1
EXEC Staging.WarehouseLoad_Customer_V1_20
EXEC Staging.WarehouseLoad_Customer_Registrations
EXEC Staging.WarehouseLoad_Customer_SmartFocusUnsubscribes_V1_3
exec Staging.WarehouseLoad_Customer_HardBounceEmailChangeV1_2
Exec Staging.WarehouseLoad_Customer_HardbounceEmailChangePart2
Exec Staging.WarehouseLoad_Customer_InvalidEmail
Exec Staging.WarehouseLoad_WGUpdate_V1_0
EXEC Staging.WarehouseLoad_Outlet_V1_5
EXEC Staging.WarehouseLoad_IronOffer_V1_2 -- Excluded because of amount of memberships
Exec Staging.WarehouseLoad_IronOfferMembers_DailySmallLoad_V2
Exec Staging.WarehouseLoad_IronWelcomeOffer_Update
Exec Staging.WarehouseLoad_PartnerTrans_V1_7_Append
EXEC Staging.WarehouseLoad_PartnerTrans_CardTypeV1
EXEC Staging.WarehouseLoad_Corrections_V1_7
Exec Staging.WarehouseLoad_RedemptionItem_V1_13
Exec Staging.WarehouseLoad_Redemptions_V1_12 --** 01-03-2018 JEA
Exec Staging.WarehouseLoad_Redemptions_Ecodes --**18-05-2017 ERA introduced
EXEC Staging.WarehouseLoad_Partner_CurrentlyActiveV1_1
Exec Staging.WarehouseLoad_Partner_UpdateAccountManager -- 04-12-2018 RF introduced AccountManager column to Relational.Partner table
EXEC Staging.WarehouseLoad_MIDTrackingGAS --**09-07-2018 RF introduced MID Tracking Table
Exec Staging.WarehouseLoad_AdditionalCashbackAwardsV1_11_Append
Exec Staging.WarehouseLoad_AdditionalCashbackAwards_CC_MonthlyAwards
Exec Staging.WarehouseLoad_AdditionalCashbackAwards_ApplePay_V1_2
Exec Staging.WarehouseLoad_AdditionalCashbackAwards_ItemAlterationsV1_0
Exec Staging.WarehouseLoad_AdditionalCashbackAdjustmentsV1_1
EXEC Staging.WarehouseLoad_SmartFocusEmailData_V1_6
EXEC Staging.WarehouseLoad_Deactivations_V1_2

EXEC MI.ElectronicRedemptionsReport_ProcessAndSend 

EXEC Staging.WarehouseLoad_WebLoginsV1_1
EXEC Staging.WarehouseLoad_Customer_EmailEngagedV1_1
EXEC Staging.WarehouseLoad_DailyAboveBaseOffersV1_1
EXEC Staging.WarehouseLoad_Customer_DuplicateSourceUIDV1_2
--EXEC Staging.WarehouseLoad_Database_TableRowCountsV1_1--- Store count of rows of a selection of tables in the warehouse -* Needed for report to judge overnight SLC_Report backup
Exec [Staging].[WarehouseLoad_Cashback_Balances_V1_2] -- New version added on recommendation from CJM
EXEC [Staging].[CustomerUnsubscribesV1_2]
EXEC [Staging].[CustomerUnsubscribeCampaignsV1_1]
Exec [Staging].[WarehouseLoad_Customer_Marketable_ButDeceased]
EXEC [Staging].[WarehouseLoad_IronOffer_PartnerCommissionRule]
EXEC [Staging].[WarehouseLoad_CustomerPaymentMethodsAvailableV1_1]
Exec [Staging].[WarehouseLoad_CustomerMarketableByEmailStatusV1_1]
Exec [Staging].[WarehouseLoad_Deactivate_Deceased_Customers]

--**********************************************************
--*********************Loyalty Additions********************
--**********************************************************
Exec [Staging].[WarehouseLoad_Customer_MarketableByEmailStatus_MI]
Exec [Staging].[WarehouseLoad_Customer_Registered_MI_V1_1]
Exec [Staging].[WarehouseLoad_DirectDebit_OINs]
Exec [Staging].[WarehouseLoad_DirectDebitOriginator]
Exec [Staging].[WarehouseLoad_Customer_RBSGSegmentsV3]
Exec [Staging].[WarehouseLoad_Customer_SchemeMembershipV1_1]
Exec [Staging].[WarehouseLoad_CustomerNominee]
Exec [Staging].[WarehouseLoad_AdditionalCashbackAdjustment_AmazonRedemptions]
--Exec [Staging].[AmazonVoucherEmailOpeners]--****************Turned off 22-06-2017

Exec [Staging].[Warehouseload_PartnerVsBrandsLookup]

--Exec Staging.WarehouseLoad_Customer_ReducedEmailFrequency --****************Removed for Q1 2016 as all emails are full audience

--**********************************************************
--*********************Temporary Fix Start******************
--**********************************************************
--While investigation into resubscribes goes on we need to make sure this RBSG staff members starts receiving emails
Update Relational.Customer
Set MarketableByEmail = 1,Unsubscribed = 0

From Warehouse.Relational.Customer as c
inner join Warehouse.Staging.StaffRecordsNotToBeUnsubscribed as sr
	on c.FanID = sr.FanID
Where	MarketableByEmail = 0


Delete from warehouse.relational.Customers_ReducedFrequency_CurrentExclusions
Where fanid = 10523426
--**********************************************************
--***********************Temporary Fix End******************
--**********************************************************

if datename(dw,getdate()) = 'Saturday' 
Begin
	EXEC Staging.Populate_SFDPostUploadAssessmentData_Member
End




if datename(dw,getdate()) = 'Sunday' 
BEGIN 
	--Exec [Staging].[WarehouseLoad_LionSendComponent_V1_2] -- 02/02/2017 SB
	--Exec Staging.WarehouseLoad_LionSendComponent_V1_3





	EXEC Staging.Update_BaseAndNonCore_StartEndDates
	--EXEC Staging.SSRS_R0097_Quidco_HalfordsWeeklyCalculation --***29-09-2017 SB - Removed as contents is now provided through a BI report.
	EXEC Staging.SSRS_R0098_Quidco_GASReportCalculation
	--Exec Staging.WarehouseLoad_DailyEmailChanges -- added for 1 week
END
if datename(dw,getdate()) = 'Monday'
Begin
Exec [Staging].[SSRS_R0164_ERA_Redemption_Stats_Populate]
End
/*******************Removed 22-06-2017 as no longer needed*************************
if datename(dw,getdate()) = 'Wednesday'
Begin
	--EXEC [Staging].[SSRS_R0097a_Quidco_HalfordsAutoCentreWeeklyCalculation]
	EXEC [Staging].[SSRS_R0097a_Quidco_HalfordsAutoCentreWeeklyCalculationV1_1]
End
*******************Removed 22-06-2017 as no longer needed*************************/
Exec Staging.SmartFocusCampaignKey_UpdateorRead 1 -- Update CampaignLionSendIDs


/******************************************************************		
		TEMPORARY FIX - REMOVE - ZT 2018-02-22 
******************************************************************/

UPDATE Warehouse.Relational.Customer
SET Hardbounced = 0, MarketableByEmail = 1
WHERE FanID in (5462272, 11064791)



/*--------------------------------------------------------------------------------------------------
-----------------------------Write End DateTime entry to JobLog Table-----------------------------
----------------------------------------------------------------------------------------------------*/

Insert into staging.JobLog
Select	StoredProcedureName = 'ETL_Build_End',
		TableSchemaName = '',
		TableName = '',
		StartDate = GETDATE(),
		EndDate = GETDATE(),
		TableRowCount  = null,
		AppendReload = NULL

END








