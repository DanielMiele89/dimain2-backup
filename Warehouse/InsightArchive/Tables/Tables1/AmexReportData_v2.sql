CREATE TABLE [InsightArchive].[AmexReportData_v2] (
    [ID]               INT          IDENTITY (1, 1) NOT NULL,
    [ReportDate]       DATE         NULL,
    [IronOfferID]      INT          NULL,
    [AmexOfferID]      VARCHAR (10) NULL,
    [SpendStretch]     MONEY        NULL,
    [CashbackOffer]    FLOAT (53)   NULL,
    [TargetAudience]   VARCHAR (50) NULL,
    [RetailerName]     VARCHAR (50) NULL,
    [Exposed_Base]     INT          NULL,
    [Enrolments]       INT          NULL,
    [Redemptions]      INT          NULL,
    [Redemption_Value] MONEY        NULL,
    [NumberOfTrans]    INT          NULL,
    [Total_Value]      MONEY        NULL,
    [Campaign_Length]  SMALLINT     NULL,
    [StartDate]        DATE         NULL,
    [EndDate]          DATE         NULL,
    [No_Of_Weeks_In]   SMALLINT     NULL,
    [No_Of_Waves_In]   SMALLINT     NULL,
    [EndOfWave]        BIT          NULL
);

